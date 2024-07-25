DECLARE active_logical_gib_price FLOAT64 DEFAULT 0.02;
DECLARE long_term_logical_gib_price FLOAT64 DEFAULT 0.01;
DECLARE active_physical_gib_price FLOAT64 DEFAULT 0.04;
DECLARE long_term_physical_gib_price FLOAT64 DEFAULT 0.02;

WITH
 storage_sizes AS (
   SELECT
     table_schema AS dataset_name,
     -- Logical
     SUM(IF(deleted=false, active_logical_bytes, 0)) / power(1024, 3) AS active_logical_gib,
     SUM(IF(deleted=false, long_term_logical_bytes, 0)) / power(1024, 3) AS long_term_logical_gib,
     -- Physical
     SUM(active_physical_bytes) / power(1024, 3) AS active_physical_gib,
     SUM(active_physical_bytes - time_travel_physical_bytes) / power(1024, 3) AS active_no_tt_physical_gib,
     SUM(long_term_physical_bytes) / power(1024, 3) AS long_term_physical_gib,
     -- Restorable previously deleted physical
     SUM(time_travel_physical_bytes) / power(1024, 3) AS time_travel_physical_gib,
     SUM(fail_safe_physical_bytes) / power(1024, 3) AS fail_safe_physical_gib,
   FROM
      `region-us`.INFORMATION_SCHEMA.TABLE_STORAGE_BY_PROJECT
   WHERE total_physical_bytes + fail_safe_physical_bytes > 0
     -- Base the forecast on base tables only for highest precision results
     AND table_type  = 'BASE TABLE'
     GROUP BY 1
 )
SELECT
  dataset_name,
  -- Logical
  ROUND(active_logical_gib, 2) AS active_logical_gib,
  ROUND(long_term_logical_gib, 2) AS long_term_logical_gib,
  -- Physical
  ROUND(active_physical_gib, 2) AS active_physical_gib,
  ROUND(long_term_physical_gib, 2) AS long_term_physical_gib,
  ROUND(time_travel_physical_gib, 2) AS time_travel_physical_gib,
  ROUND(fail_safe_physical_gib, 2) AS fail_safe_physical_gib,
  -- Compression ratio
  ROUND(SAFE_DIVIDE(active_logical_gib, active_no_tt_physical_gib), 2) AS active_compression_ratio,
  ROUND(SAFE_DIVIDE(long_term_logical_gib, long_term_physical_gib), 2) AS long_term_compression_ratio,
  -- Forecast costs logical
  ROUND(active_logical_gib * active_logical_gib_price, 2) AS forecast_active_logical_cost,
  ROUND(long_term_logical_gib * long_term_logical_gib_price, 2) AS forecast_long_term_logical_cost,
  -- Forecast costs physical
  ROUND((active_no_tt_physical_gib + time_travel_physical_gib + fail_safe_physical_gib) * active_physical_gib_price, 2) AS forecast_active_physical_cost,
  ROUND(long_term_physical_gib * long_term_physical_gib_price, 2) AS forecast_long_term_physical_cost,
  -- Forecast costs total
  ROUND(((active_logical_gib * active_logical_gib_price) + (long_term_logical_gib * long_term_logical_gib_price)) -
     (((active_no_tt_physical_gib + time_travel_physical_gib + fail_safe_physical_gib) * active_physical_gib_price) + (long_term_physical_gib * long_term_physical_gib_price)), 2) AS forecast_total_cost_difference
FROM
  storage_sizes
ORDER BY
  (forecast_active_logical_cost + forecast_active_physical_cost) DESC;
