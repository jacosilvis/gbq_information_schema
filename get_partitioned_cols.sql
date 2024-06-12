SELECT * FROM
`project-id.dataset-id.INFORMATION_SCHEMA.COLUMNS`
WHERE
 is_partitioning_column = 'YES' OR clustering_ordinal_position IS NOT NULL;
