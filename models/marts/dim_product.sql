{{ config(materialized='table') }}

WITH products AS (
    SELECT * FROM {{ ref('stg_products') }}
),

translation AS (
    SELECT 
        product_category_name, 
        product_category_name_english 
    FROM {{ source('raw', 'category_name_translation') }}
    
    UNION ALL
    
    -- Eksik 2 kategoriyi elle tamamladığımız iş kuralı
    SELECT 'pc_gamer', 'pc_gamer'
    UNION ALL
    SELECT 'portateis_cozinha_e_preparadores_de_alimentos', 'portable_kitchen_and_food_preparers'
)

SELECT
    ROW_NUMBER() OVER (ORDER BY p.product_id) AS product_key,
    p.product_id,
    COALESCE(p.product_category_name, 'unknown') AS category_name_pt,
    COALESCE(t.product_category_name_english, 'unknown') AS category_name_en
FROM products p
LEFT JOIN translation t ON p.product_category_name = t.product_category_name