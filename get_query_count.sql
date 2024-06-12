SELECT
  DATE(creation_time) as day,
  destination_table.project_id as project_id,
  destination_table.dataset_id as dataset_id,
  destination_table.table_id as table_id,
  COUNT(job_id) AS load_job_countjob_count
FROM
 region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT
WHERE
  creation_time BETWEEN TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 8 DAY) AND CURRENT_TIMESTAMP()
GROUP BY
  day,
  project_id,
  dataset_id,
  table_id
ORDER BY
  day DESC
