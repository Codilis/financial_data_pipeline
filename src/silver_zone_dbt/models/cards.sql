{{ config(
    materialized='table'
) }}

WITH source_data AS (
    SELECT
        *
    FROM
        csv.`/user/root/data/cards.csv`
)

SELECT
    *
FROM
    source_data
	