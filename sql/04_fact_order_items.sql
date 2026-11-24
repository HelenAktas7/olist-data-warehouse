USE olist;
GO

DROP TABLE IF EXISTS dw.fact_order_items;
GO
CREATE TABLE dw.fact_order_items (
    order_id          VARCHAR(50)   NOT NULL,
    order_item_id     INT           NOT NULL,
    customer_key      INT           NOT NULL,
    product_key       INT           NOT NULL,
    seller_key        INT           NOT NULL,
    order_date_key    INT           NOT NULL,
    delivered_date_key INT          NULL,
    order_status      VARCHAR(20)   NOT NULL,
    price             DECIMAL(10,2) NOT NULL,
    freight_value     DECIMAL(10,2) NOT NULL,
    delivery_days     INT           NULL,   -- siparişten teslime kaç gün
    delay_days        INT           NULL,   -- tahmini tarihe göre fark (+ = geç)
    CONSTRAINT pk_fact_order_items PRIMARY KEY (order_id, order_item_id),
    CONSTRAINT fk_fact_customer FOREIGN KEY (customer_key)       REFERENCES dw.dim_customer(customer_key),
    CONSTRAINT fk_fact_product  FOREIGN KEY (product_key)        REFERENCES dw.dim_product(product_key),
    CONSTRAINT fk_fact_seller   FOREIGN KEY (seller_key)         REFERENCES dw.dim_seller(seller_key),
    CONSTRAINT fk_fact_order_dt FOREIGN KEY (order_date_key)     REFERENCES dw.dim_date(date_key),
    CONSTRAINT fk_fact_deliv_dt FOREIGN KEY (delivered_date_key) REFERENCES dw.dim_date(date_key)
);
GO

INSERT INTO dw.fact_order_items
SELECT
    oi.order_id,
    oi.order_item_id,
    dc.customer_key,
    dp.product_key,
    ds.seller_key,
    YEAR(o.order_purchase_ts) * 10000 + MONTH(o.order_purchase_ts) * 100 + DAY(o.order_purchase_ts),
    YEAR(o.order_delivered_customer_ts) * 10000 + MONTH(o.order_delivered_customer_ts) * 100 + DAY(o.order_delivered_customer_ts),
    o.order_status,
    oi.price,
    oi.freight_value,
    DATEDIFF(DAY, o.order_purchase_ts, o.order_delivered_customer_ts),
    DATEDIFF(DAY, o.order_estimated_delivery_ts, o.order_delivered_customer_ts)
FROM staging.order_items oi
JOIN staging.orders    o  ON o.order_id = oi.order_id
JOIN staging.customers c  ON c.customer_id = o.customer_id
JOIN dw.dim_customer   dc ON dc.customer_unique_id = c.customer_unique_id
                         AND o.order_purchase_ts >= dc.valid_from
                         AND o.order_purchase_ts <  dc.valid_to
JOIN dw.dim_product    dp ON dp.product_id = oi.product_id
JOIN dw.dim_seller     ds ON ds.seller_id  = oi.seller_id;
GO