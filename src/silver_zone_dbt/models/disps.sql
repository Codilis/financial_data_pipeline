{{ config(
    materialized='table'
) }}

WITH source_data AS (
    SELECT
        *
    FROM
        csv.`/user/root/data/disps.csv`
)

SELECT
    *
FROM
    source_data
	