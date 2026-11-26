{{ config(materialized='view') }}

WITH source AS (
    SELECT * FROM {{ source('raw', 'customers') }}
),

renamed_and_cleaned AS (
    SELECT
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state
    FROM source
)

SELECT * FROM renamed_and_cleaned