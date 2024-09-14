{{ config(
    materialized='table'
) }}

WITH source_data AS (
    SELECT
        *
    FROM
        csv.`/user/root/data/clients.csv`
)

SELECT
    *
FROM
    source_data
	