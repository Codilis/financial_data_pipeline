{{ config(
    materialized='incremental',
    unique_key = 'id'
) }}

WITH source_data AS (
    SELECT
        *
    FROM
        parquet.`/user/root/data/transactions`
)

SELECT
    *
FROM
    source_data
	