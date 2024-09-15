{{ config(
    materialized='incremental'
) }}

WITH source_data AS (
    SELECT
        *
    FROM
        {{ source('silver_zone', 'accounts') }}
)

SELECT
    *
FROM
    source_data
	