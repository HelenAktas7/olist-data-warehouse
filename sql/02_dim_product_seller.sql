USE olist;
GO

-- dim_product
DROP TABLE IF EXISTS dw.dim_product;
GO
CREATE TABLE dw.dim_product (
    product_key      INT IDENTITY(1,1) PRIMARY KEY,
    product_id       VARCHAR(50)  NOT NULL UNIQUE,
    category_name_pt VARCHAR(100) NOT NULL,
    category_name_en VARCHAR(100) NOT NULL
);
GO
INSERT INTO dw.dim_product (product_id, category_name_pt, category_name_en)
SELECT
    p.product_id,
    COALESCE(p.product_category_name, 'unknown'),
    COALESCE(t.product_category_name_english, 'unknown')
FROM staging.products p
LEFT JOIN staging.category_translation t
       ON p.product_category_name = t.product_category_name;
GO

-- dim_seller
DROP TABLE IF EXISTS dw.dim_seller;
GO
CREATE TABLE dw.dim_seller (
    seller_key   INT IDENTITY(1,1) PRIMARY KEY,
    seller_id    VARCHAR(50)  NOT NULL UNIQUE,
    seller_city  VARCHAR(100) NULL,
    seller_state VARCHAR(10)  NULL
);
GO
INSERT INTO dw.dim_seller (seller_id, seller_city, seller_state)
SELECT seller_id, seller_city, seller_state
FROM staging.sellers;
GO