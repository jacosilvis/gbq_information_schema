SELECT
  t1.period_start,
  t1.job_count AS dynamic_concurrency_threshold
FROM (
  SELECT
    period_start,
    state,
    COUNT(DISTINCT job_id) AS job_count
  FROM
    `region-us`.INFORMATION_SCHEMA.JOBS_TIMELINE
  WHERE
    period_start BETWEEN TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY)
    AND CURRENT_TIMESTAMP()
    AND reservation_id = "RESERVATION_ID"
  GROUP BY
    period_start,
    state) AS t1
JOIN (
  SELECT
    period_start,
    state,
    COUNT(DISTINCT job_id) AS job_count
  FROM
    `region-us`.INFORMATION_SCHEMA.JOBS_TIMELINE
  WHERE
    state = "PENDING"
    AND period_start BETWEEN TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY)
    AND CURRENT_TIMESTAMP()
    AND reservation_id = "RESERVATION_ID"
  GROUP BY
    period_start,
    state
  HAVING
    COUNT(DISTINCT job_id) > 0 ) AS t2
ON
  t1.period_start = t2.period_start
WHERE
  t1.state = "RUNNING";
