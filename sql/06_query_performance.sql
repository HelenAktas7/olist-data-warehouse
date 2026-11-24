USE olist;
GO

-- 1. İndeksi Oluştur
CREATE NONCLUSTERED INDEX ix_fact_order_items_date_perf
ON dw.fact_order_items (order_date_key)
INCLUDE (product_key, price);
GO

-- 2. İndeks Oluştuktan Sonra Aynı Sorguyu Tekrar Çalıştır
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

SELECT 
    p.category_name_en,
    SUM(f.price) AS total_revenue,
    COUNT(*) AS total_items
FROM dw.fact_order_items f
JOIN dw.dim_date d ON f.order_date_key = d.date_key
JOIN dw.dim_product p ON f.product_key = p.product_key
WHERE d.year_number = 2017 AND d.month_number = 5
GROUP BY p.category_name_en
ORDER BY total_revenue DESC;
GO