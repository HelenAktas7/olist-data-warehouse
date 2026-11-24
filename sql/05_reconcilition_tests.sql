USE olist;
GO
-- TEST 1: Satır Sayısı Mutabakatı (Reconciliation / Data Loss Check)
-- 
-- Dikkat Edilecek Nokta: 
-- Kaynak (raw) -> Temizleme (staging) -> Yıldız Şema (dw) akışında hiç satır 
-- kaybettik mi ya da hatalı JOIN yüzünden veri çoğaldı mı (fan-out)?
-- Beklenti: Üç tabloda da satır sayısı TAM
SELECT 'raw.order_items' AS katman, COUNT(*) AS satir_sayisi FROM raw.order_items
UNION ALL
SELECT 'staging.order_items', COUNT(*) FROM staging.order_items
UNION ALL
SELECT 'dw.fact_order_items', COUNT(*) FROM dw.fact_order_items;
GO
-- TEST 2: Tekillik Testi (dbt 'unique' testi)
--
-- Dikkat Edilecek Nokta:
-- Fact tablomuzun tanesi (grain) bir sipariş kalemidir. 
-- Yani aynı (order_id, order_item_id) çifti tabloda ASLA 2 kez bulunamaz.
-- Beklenti: 0 SATIR dönmelidir!
-- ============================================================================
SELECT 
    order_id, 
    order_item_id, 
    COUNT(*) AS tekrar_sayisi
FROM dw.fact_order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;
GO
-- ============================================================================
-- TEST 3: Boyut Bütünlüğü & Yetim Kayıt Testi (dbt 'relationships' ve 'not_null')
--
-- Dikkat Edilecek Nokta:
-- Fact tablosundaki yabancı anahtarların (customer_key, product_key vb.)
-- karşılıkları boyut (dim) tablolarında GERÇEKTEN var mı? 
-- LEFT JOIN yapıp boyutta karşılığı gelmeyen (NULL kalan) kayıt arıyoruz.
-- Beklenti: 0 SATIR (veya 0 sayısı) dönmelidir!
-- ============================================================================
SELECT 
    COUNT(*) AS yetim_kayit_sayisi
FROM dw.fact_order_items f
LEFT JOIN dw.dim_customer c ON f.customer_key = c.customer_key
LEFT JOIN dw.dim_product  p ON f.product_key = p.product_key
LEFT JOIN dw.dim_seller   s ON f.seller_key = s.seller_key
LEFT JOIN dw.dim_date     d ON f.order_date_key = d.date_key
WHERE c.customer_key IS NULL 
   OR p.product_key IS NULL 
   OR s.seller_key IS NULL 
   OR d.date_key IS NULL;
GO
-- ============================================================================
-- TEST 4: Özel İş Kuralı Testi (dbt 'singular / custom' test)
--
-- Dikkat Edilecek Nokta:
-- Bir e-ticaret platformunda bir ürünün fiyatı veya kargo ücreti negatif olamaz.
-- Negatif olan her satır bir veri bozulması (corruption) veya bug işaretidir.
-- Beklenti: 0 SATIR dönmelidir!
-- ============================================================================
SELECT 
    order_id, 
    order_item_id, 
    price, 
    freight_value
FROM dw.fact_order_items
WHERE price < 0 OR freight_value < 0;
GO
-- ============================================================================
-- TEST 5: Başarısız Test Simülasyonu (Bilinçli Olarak Hata Tetikleme)
--
-- Dikkat Edilecek Nokta:
-- "Test mekanizmamın çalıştığından nasıl emin olurum?"
-- Bilerek gerçekçi olmayan bir kural koyarız. Örneğin:
-- "Bu sitede 500 BRL (Brezilya Reali) üzerinde ürün satılamaz!" varsayımı yapalım.
-- Beklenti: Test FAIL etmeli, yani 500'den büyük kayıtları yakalayıp ekrana dökmelidir.
-- ============================================================================
SELECT 
    order_id, 
    order_item_id, 
    price
FROM dw.fact_order_items
WHERE price > 500;
GO
