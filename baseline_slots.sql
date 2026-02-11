WITH minute_usage AS (
  SELECT
    TIMESTAMP_TRUNC(creation_time, MINUTE) AS usage_minute,
    -- Calculate average concurrent slots per minute
    SUM(total_slot_ms) / (1000 * 60) AS concurrent_slots
  FROM
    `region-us`.INFORMATION_SCHEMA.JOBS
  WHERE
    -- Look at the last 30 days for a stable baseline
    creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
    AND state = 'DONE'
  GROUP BY 1
)
SELECT
  -- The Median (50th percentile) is often the safest "Efficient Baseline"
  PERCENTILE_CONT(concurrent_slots, 0.5) OVER() AS median_baseline_slots,
  -- The Average gives you a "Safe Baseline"
  AVG(concurrent_slots) OVER() AS avg_baseline_slots,
  -- The 25th percentile is your "Conservative/Minimum Baseline"
  PERCENTILE_CONT(concurrent_slots, 0.25) OVER() AS floor_baseline_slots
FROM
  minute_usage
LIMIT 1
