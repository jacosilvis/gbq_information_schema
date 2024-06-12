SELECT
  table_schema AS dataset_name,
  SUM(active_logical_bytes) / power(1024, 3) AS total_active_logical_GiB,
  SUM(long_term_logical_bytes) / power(1024, 3) AS total_long_term_logical_GiB,
  SUM(active_physical_bytes) / power(1024, 3) AS total_active_physical_GiB,
  SUM(long_term_physical_bytes) / power(1024, 3) AS total_long_term_physical_GiB,
FROM
  `region-us`.INFORMATION_SCHEMA.TABLE_STORAGE
GROUP BY
  1
;
