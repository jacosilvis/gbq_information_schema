-- V10: FinOps Model with Minute-Level Slot Percentiles

DECLARE interval_days INT64 DEFAULT 30;
-- Enterprise Edition Slot Pricing Variables
DECLARE price_1yr_commit FLOAT64 DEFAULT 0.032; 
DECLARE price_3yr_commit FLOAT64 DEFAULT 0.024;
DECLARE slot_hour_autoscale_price FLOAT64 DEFAULT 0.06;

WITH minute_usage AS (
  SELECT
    TIMESTAMP_TRUNC(creation_time, MINUTE) AS minute_bucket,
    SUM(total_slot_ms) / (1000 * 60) AS concurrent_slots_per_minute,
    SUM(total_bytes_billed) / POW(10, 12) * 6.25 AS actual_ondemand_cost
  FROM `region-australia-southeast1`.INFORMATION_SCHEMA.JOBS_BY_ORGANIZATION 
  WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL interval_days DAY)
    AND job_type = 'QUERY'
    AND statement_type != 'SCRIPT' 
  GROUP BY 1
),
slot_stats AS (
  -- Calculate the global statistics across the entire 30-day window
  SELECT 
    ROUND(AVG(concurrent_slots_per_minute), 0) AS avg_slots,
    ROUND(APPROX_QUANTILES(concurrent_slots_per_minute, 100)[OFFSET(50)], 0) AS median_slots,
    ROUND(APPROX_QUANTILES(concurrent_slots_per_minute, 100)[OFFSET(90)], 0) AS p90_slots,
    ROUND(APPROX_QUANTILES(concurrent_slots_per_minute, 100)[OFFSET(95)], 0) AS p95_slots,
    ROUND(APPROX_QUANTILES(concurrent_slots_per_minute, 100)[OFFSET(99)], 0) AS p99_slots,
    ROUND(MAX(concurrent_slots_per_minute), 0) AS max_slots
  FROM minute_usage
),
scenarios AS (
  SELECT baseline_limit FROM UNNEST(GENERATE_ARRAY(0, 3000, 100)) AS baseline_limit
),
totals AS (
  SELECT
    s.baseline_limit,
    SUM(m.actual_ondemand_cost) AS total_ondemand_spend,
    SUM(m.concurrent_slots_per_minute) / 60 AS total_consumed_slot_hours,
    SUM(GREATEST(0, m.concurrent_slots_per_minute - s.baseline_limit)) / 60 AS autoscale_slot_hours,
    (SUM(GREATEST(0, m.concurrent_slots_per_minute - s.baseline_limit)) / 60) * slot_hour_autoscale_price AS variable_autoscale_cost
  FROM scenarios s
  CROSS JOIN minute_usage m
  GROUP BY 1
)
SELECT
  t.baseline_limit,
  ROUND(t.total_ondemand_spend, 2) AS current_ondemand_total,
  
  -- NEW: USAGE PERCENTILES (Repeated on every row for easy visual comparison)
  st.avg_slots,
  st.median_slots,
  st.p90_slots,
  st.p95_slots,
  st.p99_slots,
  st.max_slots,

  -- COMPUTE USAGE COMPARISON
  ROUND(t.total_consumed_slot_hours, 0) AS total_consumed_slot_hours,
  (t.baseline_limit * 24 * interval_days) AS committed_baseline_slot_hours,
  ROUND(t.autoscale_slot_hours, 0) AS autoscale_slot_hours,
  
  ROUND(t.variable_autoscale_cost, 2) AS expected_autoscale_cost,
  
  -- 1-YEAR COMMITMENT
  ROUND((t.baseline_limit * price_1yr_commit * 24 * interval_days) + t.variable_autoscale_cost, 2) AS total_1yr_plan_cost,
  ROUND(t.total_ondemand_spend - ((t.baseline_limit * price_1yr_commit * 24 * interval_days) + t.variable_autoscale_cost), 2) AS net_savings_1yr,
  
  -- 3-YEAR COMMITMENT
  ROUND((t.baseline_limit * price_3yr_commit * 24 * interval_days) + t.variable_autoscale_cost, 2) AS total_3yr_plan_cost,
  ROUND(t.total_ondemand_spend - ((t.baseline_limit * price_3yr_commit * 24 * interval_days) + t.variable_autoscale_cost), 2) AS net_savings_3yr
  
FROM totals t
CROSS JOIN slot_stats st
ORDER BY t.baseline_limit;
