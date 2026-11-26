{{ config(materialized='view') }}

WITH source AS (
    SELECT * FROM {{ source('raw', 'sellers') }}
),

renamed_and_cleaned AS (
    SELECT
        seller_id,
        seller_zip_code_prefix,
        seller_city,
        seller_state
    FROM source
)

SELECT * FROM renamed_and_cleaned