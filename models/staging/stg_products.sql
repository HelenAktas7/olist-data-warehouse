{{ config(materialized='view') }}

WITH source AS (
    SELECT * FROM {{ source('raw', 'products') }}
),

renamed_and_cleaned AS (
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
    FROM source
)

SELECT * FROM renamed_and_cleaned