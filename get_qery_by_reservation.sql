SELECT
 DISTINCT job_id,
 reservation_id,
 job_type,
 start_time,
 SUM(total_bytes_processed) AS total_bytes_processed,
 SUM(total_bytes_billed) AS total_bytes_billed,
 user_email,
 query
FROM
 `region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT`
WHERE
 # project_id = '' AND
  total_bytes_processed IS NOT NULL
 AND total_bytes_billed IS NOT NULL
 AND total_bytes_billed > 0
 AND creation_time BETWEEN TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY)
 AND CURRENT_TIMESTAMP()
GROUP BY
 job_id,
 job_type,
 reservation_id,
 start_time,
 user_email,
 query
