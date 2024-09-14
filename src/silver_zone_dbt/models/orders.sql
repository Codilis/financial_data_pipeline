{{ config(
    materialized='table'
) }}

WITH source_data AS (
    SELECT
        *
    FROM
        csv.`/user/root/data/orders.csv`
)

SELECT
    *
FROM
    source_data
	