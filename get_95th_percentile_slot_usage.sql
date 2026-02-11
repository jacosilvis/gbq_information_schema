/*
flattens usage into 1-second intervals to see how many slots were active at any given moment, then calculates the percentile across those seconds.
*/
WITH job_stats AS (
  SELECT
    project_id,
    job_id,
    creation_time,
    end_time,
    -- Calculate slot seconds for each job
    total_slot_ms / 1000 AS slot_seconds
  FROM
    `region-us`.INFORMATION_SCHEMA.JOBS
  WHERE
    creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
    AND state = 'DONE'
    AND job_type = 'QUERY'
),
second_by_second_usage AS (
  -- This approximates concurrency by spreading slot_ms over the job duration
  SELECT
    TIMESTAMP_TRUNC(creation_time, SECOND) AS usage_second,
    SUM(total_slot_ms / 1000 / NULLIF(TIMESTAMP_DIFF(end_time, creation_time, SECOND), 0)) AS estimated_slots
  FROM
    `region-us`.INFORMATION_SCHEMA.JOBS
  WHERE
    creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
    AND end_time > creation_time
  GROUP BY 1
)
SELECT
  PERCENTILE_CONT(estimated_slots, 0.95) OVER() AS slot_95th_percentile,
  MAX(estimated_slots) OVER() AS peak_slots,
  AVG(estimated_slots) OVER() AS avg_slots
FROM
  second_by_second_usage
LIMIT 1
