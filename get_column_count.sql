# check for wide or skinny tables
SELECT table_schema, table_name, count(1) as Col_count
FROM
`project-id.dataset-id.INFORMATION_SCHEMA.COLUMNS`
Group by table_schema, table_name;
