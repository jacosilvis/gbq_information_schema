SELECT
 creation_time,
 project_id,
 user_email,
 job_id,
 job_type,
 priority,
 state,
 query,
 TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), start_time,second) as running_time_sec,
 total_slot_ms / TIMESTAMP_DIFF(end_time,start_time,MILLISECOND) as num_slot
FROM
`region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT`
WHERE
 creation_time BETWEEN TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 100 DAY) AND CURRENT_TIMESTAMP() AND
 --  state != "DONE" AND
 1 = 1
ORDER BY
 total_slot_ms / TIMESTAMP_DIFF(end_time,start_time,MILLISECOND) desc, running_time_sec DESC;
