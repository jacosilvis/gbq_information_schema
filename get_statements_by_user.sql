# get jobs, by users ordered desc by exec time
# Replace region in from clause, example:region-us, region-australia-southeast1 ,region-asia-east2, region-europe-north1
# regions here: https://cloud.google.com/compute/docs/regions-zones#available
SELECT
 project_id,
 job_id,
 job_type,
 state,
 creation_time,
 start_time,
 user_email,
 query,
 TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), start_time,second) as running_time_sec,
 total_slot_ms / TIMESTAMP_DIFF(end_time,start_time,MILLISECOND) as num_slot
FROM
 `region-australia-southeast1`.INFORMATION_SCHEMA.JOBS_BY_PROJECT 
Where creation_time between '2024-09-19' and '2024-09-24'
ORDER BY
 total_slot_ms desc;
