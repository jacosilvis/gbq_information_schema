-- Estimate on-demand billing vs Enterprise editions per project
DECLARE ented_price FLOAT64 DEFAULT 0.081;
DECLARE ondemand_price FLOAT64 DEFAULT 8.13;
DECLARE auto_scale_factor FLOAT64 DEFAULT 1.2;
SELECT
  DATE_TRUNC(DATE(creation_time), MONTH) AS usage_month,
  project_id,
 (SUM(total_bytes_billed)/POWER(2,40)) AS total_bytes_billed_TiB,
  ( (SUM(total_bytes_billed)/POWER(2,40))  * ondemand_price) AS on_demand_cost_estimate,
  SUM(total_slot_ms) AS total_slot_ms,
  ((SUM(total_slot_ms) * ented_price) / (1000 * 60 * 60) ) * auto_scale_factor AS enterprise_editions_cost_estimate
FROM `region-australia-southeast1`.INFORMATION_SCHEMA.JOBS_BY_ORGANIZATION
WHERE
  DATE(creation_time) between DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH) and Current_date() and
  statement_type != 'SCRIPT'
GROUP BY usage_month, project_id
ORDER BY usage_month DESC, total_bytes_billed_TiB DESC
