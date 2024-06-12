SELECT
 dataset_id,
 table_id,
 ROUND(size_bytes/pow(10,9),2) as size_gb,
 TIMESTAMP_MILLIS(creation_time) AS creation_time,
 TIMESTAMP_MILLIS(last_modified_time) as last_modified_time,
 row_count,
 CASE
   WHEN type = 1 THEN 'table'
   WHEN type = 2 THEN 'view'
 ELSE NULL
 END AS type
FROM
 `project-id.dataset-id.__TABLES__`
ORDER BY size_gb DESC;
