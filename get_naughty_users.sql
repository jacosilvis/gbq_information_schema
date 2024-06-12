SELECT
 user_email,
 SUM(total_bytes_billed) AS bytes_billed
FROM
 `region-us`.INFORMATION_SCHEMA.JOBS
WHERE
 job_type = 'QUERY'
 AND statement_type != 'SCRIPT'
GROUP BY
 user_email
 Order by 2 desc;
