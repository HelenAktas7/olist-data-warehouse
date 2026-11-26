{{
    config(
        materialized='incremental',
        unique_key=['order_id', 'order_item_id']
    )
}}

WITH order_items AS (
    SELECT * FROM {{ ref('stg_order_items') }}
),

orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),

customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
),

dim_customer AS (
    SELECT * FROM {{ ref('dim_customer') }}
),

dim_product AS (
    SELECT * FROM {{ ref('dim_product') }}
),

dim_seller AS (
    SELECT * FROM {{ ref('dim_seller') }}
)

SELECT
    oi.order_id,
    oi.order_item_id,
    dc.customer_key,
    dp.product_key,
    ds.seller_key,
    YEAR(o.order_purchase_ts) * 10000 + MONTH(o.order_purchase_ts) * 100 + DAY(o.order_purchase_ts) AS order_date_key,
    YEAR(o.order_delivered_customer_ts) * 10000 + MONTH(o.order_delivered_customer_ts) * 100 + DAY(o.order_delivered_customer_ts) AS delivered_date_key,
    o.order_status,
    o.order_purchase_ts,
    oi.price,
    oi.freight_value,
    DATEDIFF(day, o.order_purchase_ts, o.order_delivered_customer_ts) AS delivery_days,
    DATEDIFF(day, o.order_estimated_delivery_ts, o.order_delivered_customer_ts) AS delay_days
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
JOIN customers c ON c.customer_id = o.customer_id
JOIN dim_customer dc ON dc.customer_unique_id = c.customer_unique_id
                    AND o.order_purchase_ts >= dc.valid_from
                    AND o.order_purchase_ts < dc.valid_to
JOIN dim_product dp ON dp.product_id = oi.product_id
JOIN dim_seller ds ON ds.seller_id = oi.seller_id

{% if is_incremental() %}
    -- Incremental Filtresi: Sadece mevcut tablodaki son tarihten sonraki siparişleri ekler!
    WHERE o.order_purchase_ts > (SELECT MAX(order_purchase_ts) FROM {{ this }})
{% endif %}