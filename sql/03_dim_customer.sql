USE olist;
GO

DROP TABLE IF EXISTS dw.dim_customer;
GO
CREATE TABLE dw.dim_customer (
    customer_key       INT IDENTITY(1,1) PRIMARY KEY,
    customer_unique_id VARCHAR(50)  NOT NULL,
    customer_city      VARCHAR(100) NULL,
    customer_state     VARCHAR(10)  NULL,
    valid_from         DATETIME2    NOT NULL,
    valid_to           DATETIME2    NOT NULL,
    is_current         BIT          NOT NULL
);
GO

WITH order_history AS (            -- her sipariş: kim, hangi şehirden, ne zaman
    SELECT c.customer_unique_id, c.customer_city, c.customer_state,
           o.order_purchase_ts, o.customer_id
    FROM staging.orders o
    JOIN staging.customers c ON c.customer_id = o.customer_id
),
flagged AS (                       -- önceki siparişle şehir/eyalet aynı mı?
    SELECT *,
        CASE WHEN LAG(customer_city)  OVER (PARTITION BY customer_unique_id ORDER BY order_purchase_ts, customer_id) = customer_city
              AND LAG(customer_state) OVER (PARTITION BY customer_unique_id ORDER BY order_purchase_ts, customer_id) = customer_state
             THEN 0 ELSE 1 END AS is_new_version
    FROM order_history
),
numbered AS (                      -- 1/0 işaretlerini biriktirip versiyon numarası üret
    SELECT *,
        SUM(is_new_version) OVER (PARTITION BY customer_unique_id
                                  ORDER BY order_purchase_ts, customer_id
                                  ROWS UNBOUNDED PRECEDING) AS version_no
    FROM flagged
),
versions AS (                      -- her versiyon için tek satır
    SELECT customer_unique_id, version_no,
           MIN(order_purchase_ts) AS valid_from,
           MIN(customer_city)     AS customer_city,
           MIN(customer_state)    AS customer_state
    FROM numbered
    GROUP BY customer_unique_id, version_no
)
INSERT INTO dw.dim_customer
    (customer_unique_id, customer_city, customer_state, valid_from, valid_to, is_current)
SELECT
    customer_unique_id, customer_city, customer_state, valid_from,
    COALESCE(LEAD(valid_from) OVER (PARTITION BY customer_unique_id ORDER BY version_no),
             '9999-12-31') AS valid_to,
    CASE WHEN LEAD(valid_from) OVER (PARTITION BY customer_unique_id ORDER BY version_no) IS NULL
         THEN 1 ELSE 0 END AS is_current
FROM versions
ORDER BY customer_unique_id, version_no;
GO