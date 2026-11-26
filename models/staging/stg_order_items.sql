{{ config(materialized='view') }}

WITH source AS (
    SELECT * FROM {{ source('raw', 'order_items') }}
),

renamed_and_cleaned AS (
    SELECT
        order_id,
        TRY_CONVERT(int, NULLIF(order_item_id, ''))               AS order_item_id,
        product_id,
        seller_id,
        TRY_CONVERT(datetime2, NULLIF(shipping_limit_date, ''))   AS shipping_limit_ts,
        TRY_CONVERT(decimal(10,2), NULLIF(price, ''))             AS price,
        TRY_CONVERT(decimal(10,2), NULLIF(freight_value, ''))     AS freight_value
    FROM source
)

SELECT * FROM renamed_and_cleaned