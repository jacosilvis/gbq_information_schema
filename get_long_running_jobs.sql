# get jobs taking longer than 30 min 
# Replace region in from clause, example:region-us, region-asia-east2, region-europe-north1

SELECT
 job_id,
 job_type,
 state,
 creation_time,
 start_time,
 user_email
FROM
 `region-us`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
WHERE
 state!="DONE"
 AND creation_time <= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 MINUTE)
ORDER BY
 creation_time ASC;
