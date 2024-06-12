SELECT
 t.project_id,
 t.dataset_id,
 t.table_id,
 COUNT(*) AS num_references
FROM
 `region-us`.INFORMATION_SCHEMA.JOBS, UNNEST(referenced_tables) AS t
GROUP BY
 t.project_id,
 t.dataset_id,
 t.table_id
ORDER BY
 num_references DESC;
