CREATE OR REPLACE TABLE `{{PROJECT_ID}}.mart.retention_capacity_marginal_gain` AS
WITH sim AS (
  SELECT *
  FROM `{{PROJECT_ID}}.mart.retention_what_if_simulator`
),
pairs AS (
  SELECT
    a.snapshot_date,
    a.risk_threshold,
    a.capacity_limit AS base_capacity,
    b.capacity_limit AS new_capacity,
    a.net_expected_value AS base_value,
    b.net_expected_value AS new_value
  FROM sim AS a
  INNER JOIN sim AS b
    ON a.snapshot_date = b.snapshot_date
   AND a.risk_threshold = b.risk_threshold
   AND b.capacity_limit > a.capacity_limit
)
SELECT
  snapshot_date,
  risk_threshold,
  base_capacity,
  new_capacity,
  new_value - base_value AS marginal_net_value
FROM pairs;
