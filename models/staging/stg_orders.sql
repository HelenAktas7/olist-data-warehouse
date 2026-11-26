{{ config(materialized='view') }}

WITH source AS (
    SELECT * FROM {{ source('raw', 'orders') }}
),

renamed_and_cleaned AS (
    SELECT
        order_id,
        customer_id,
        order_status,
        TRY_CONVERT(datetime2, NULLIF(order_purchase_timestamp, ''))      AS order_purchase_ts,
        TRY_CONVERT(datetime2, NULLIF(order_approved_at, ''))             AS order_approved_ts,
        TRY_CONVERT(datetime2, NULLIF(order_delivered_carrier_date, ''))  AS order_delivered_carrier_ts,
        TRY_CONVERT(datetime2, NULLIF(order_delivered_customer_date, '')) AS order_delivered_customer_ts,
        TRY_CONVERT(datetime2, NULLIF(order_estimated_delivery_date, '')) AS order_estimated_delivery_ts
    FROM source
)

SELECT * FROM renamed_and_cleaned