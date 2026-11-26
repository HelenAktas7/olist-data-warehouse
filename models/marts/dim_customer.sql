{{ config(materialized='table') }}

WITH order_history AS (
    SELECT 
        c.customer_unique_id, 
        c.customer_city, 
        c.customer_state,
        o.order_purchase_ts, 
        o.customer_id
    FROM {{ ref('stg_orders') }} o
    JOIN {{ ref('stg_customers') }} c ON c.customer_id = o.customer_id
),

flagged AS (
    SELECT *,
        CASE 
            WHEN LAG(customer_city)  OVER (PARTITION BY customer_unique_id ORDER BY order_purchase_ts, customer_id) = customer_city
             AND LAG(customer_state) OVER (PARTITION BY customer_unique_id ORDER BY order_purchase_ts, customer_id) = customer_state
            THEN 0 ELSE 1 
        END AS is_new_version
    FROM order_history
),

numbered AS (
    SELECT *,
        SUM(is_new_version) OVER (
            PARTITION BY customer_unique_id 
            ORDER BY order_purchase_ts, customer_id 
            ROWS UNBOUNDED PRECEDING
        ) AS version_no
    FROM flagged
),

versions AS (
    SELECT 
        customer_unique_id, 
        version_no,
        MIN(order_purchase_ts) AS valid_from,
        MIN(customer_city)     AS customer_city,
        MIN(customer_state)    AS customer_state
    FROM numbered
    GROUP BY customer_unique_id, version_no
)

SELECT
    ROW_NUMBER() OVER (ORDER BY customer_unique_id, version_no) AS customer_key,
    customer_unique_id,
    customer_city,
    customer_state,
    valid_from,
    COALESCE(
        LEAD(valid_from) OVER (PARTITION BY customer_unique_id ORDER BY version_no),
        CAST('9999-12-31' AS DATETIME2)
    ) AS valid_to,
    CASE 
        WHEN LEAD(valid_from) OVER (PARTITION BY customer_unique_id ORDER BY version_no) IS NULL 
        THEN 1 ELSE 0 
    END AS is_current
FROM versions