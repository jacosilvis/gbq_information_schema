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



-- working hours only
WITH minute_usage AS (
  SELECT
    TIMESTAMP_TRUNC(creation_time, MINUTE) AS usage_minute,
    -- Calculate average concurrent slots per minute
    SUM(total_slot_ms) / (1000 * 60) AS concurrent_slots
  FROM
    `region-us`.INFORMATION_SCHEMA.JOBS
  WHERE
    -- Look at the last 30 days
    creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
    AND state = 'DONE'
    
    -- TIME FILTER: Only include jobs between 08:00 and 17:30
    AND (
      EXTRACT(HOUR FROM creation_time) BETWEEN 8 AND 16  -- Covers 08:00 to 16:59
      OR (EXTRACT(HOUR FROM creation_time) = 17 AND EXTRACT(MINUTE FROM creation_time) <= 30) -- Covers 17:00 to 17:30
    )
  GROUP BY 1
)
SELECT
  -- The Median (50th percentile) - Recommended Balance
  ROUND(PERCENTILE_CONT(concurrent_slots, 0.5) OVER(), -2) AS median_baseline_rounded,
  
  -- The Average - Safe for steady streams
  ROUND(AVG(concurrent_slots) OVER(), -2) AS avg_baseline_rounded,
  
  -- The 25th percentile - Conservative for bursty loads
  ROUND(PERCENTILE_CONT(concurrent_slots, 0.25) OVER(), -2) AS floor_baseline_rounded,

  -- Raw values (unrounded) for reference
  PERCENTILE_CONT(concurrent_slots, 0.5) OVER() AS median_raw,
  AVG(concurrent_slots) OVER() AS avg_raw
FROM
  minute_usage
LIMIT 1
