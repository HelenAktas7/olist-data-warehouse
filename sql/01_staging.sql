USE olist;
GO

IF SCHEMA_ID('staging') IS NULL EXEC('CREATE SCHEMA staging');
GO

-- orders
DROP TABLE IF EXISTS staging.orders;
SELECT
    order_id,
    customer_id,
    order_status,
    TRY_CONVERT(datetime2, NULLIF(order_purchase_timestamp, ''))      AS order_purchase_ts,
    TRY_CONVERT(datetime2, NULLIF(order_approved_at, ''))             AS order_approved_ts,
    TRY_CONVERT(datetime2, NULLIF(order_delivered_carrier_date, ''))  AS order_delivered_carrier_ts,
    TRY_CONVERT(datetime2, NULLIF(order_delivered_customer_date, '')) AS order_delivered_customer_ts,
    TRY_CONVERT(datetime2, NULLIF(order_estimated_delivery_date, '')) AS order_estimated_delivery_ts
INTO staging.orders
FROM raw.orders;
GO

-- order_items
DROP TABLE IF EXISTS staging.order_items;
SELECT
    order_id,
    TRY_CONVERT(int, NULLIF(order_item_id, ''))               AS order_item_id,
    product_id,
    seller_id,
    TRY_CONVERT(datetime2, NULLIF(shipping_limit_date, ''))   AS shipping_limit_ts,
    TRY_CONVERT(decimal(10,2), NULLIF(price, ''))             AS price,
    TRY_CONVERT(decimal(10,2), NULLIF(freight_value, ''))     AS freight_value
INTO staging.order_items
FROM raw.order_items;
GO

-- customers (posta kodu metin kalsin)
DROP TABLE IF EXISTS staging.customers;
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
INTO staging.customers
FROM raw.customers;
GO

-- sellers
DROP TABLE IF EXISTS staging.sellers;
SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
INTO staging.sellers
FROM raw.sellers;
GO

-- products
DROP TABLE IF EXISTS staging.products;
SELECT
    product_id,
    NULLIF(product_category_name, '')                          AS product_category_name,
    TRY_CONVERT(int, NULLIF(product_name_lenght, ''))          AS product_name_length,
    TRY_CONVERT(int, NULLIF(product_description_lenght, ''))   AS product_description_length,
    TRY_CONVERT(int, NULLIF(product_photos_qty, ''))           AS product_photos_qty,
    TRY_CONVERT(int, NULLIF(product_weight_g, ''))             AS product_weight_g,
    TRY_CONVERT(int, NULLIF(product_length_cm, ''))            AS product_length_cm,
    TRY_CONVERT(int, NULLIF(product_height_cm, ''))            AS product_height_cm,
    TRY_CONVERT(int, NULLIF(product_width_cm, ''))             AS product_width_cm
INTO staging.products
FROM raw.products;
GO

-- category_translation (eksik 2 kategori elle eklenir)
DROP TABLE IF EXISTS staging.category_translation;
SELECT
    product_category_name,
    product_category_name_english
INTO staging.category_translation
FROM raw.category_name_translation;

INSERT INTO staging.category_translation (product_category_name, product_category_name_english)
VALUES
    ('pc_gamer', 'pc_gamer'),
    ('portateis_cozinha_e_preparadores_de_alimentos', 'portable_kitchen_and_food_preparers');
GO