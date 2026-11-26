🛒 Olist Perakende Veri Ambarı (End-to-End Retail Data Warehouse)

SQL Server
dbt
Python
Power BI
Docker

Brezilya'nın en büyük e-ticaret platformlarından Olist'in ~100.000 sipariş verisini kullanarak ham CSV'den iş zekası dashboard'una kadar uzanan, Kimball Yıldız Şema, SCD Type 2, dbt ile ELT dönüşümü, sorgu performansı optimizasyonu ve Docker konteynerizasyonu içeren uçtan uca modern veri ambarı projesi.

🏗️ 1. Mimari (Architecture)

Proje, modern ELT (Extract - Load - Transform) yaklaşımını benimser:

📐 2. Veri Modelleme (Kimball Star Schema)
Grain (Tane): Bir sipariş kalemi (order_id, order_item_id).
Olgu Tablosu (Fact): fact_order_items (Fiyat, navlun bedeli, teslimat süresi, gecikme farkı).
Boyut Tabloları (Dimensions):
dim_product: Kategori çevirileri ile zenginleştirilmiş ürün bilgisi.
dim_seller: Satıcı konumu ve kimliği.
dim_date: 2016-2018 yıllarını kapsayan, akıllı tamsayı anahtarlı (YYYYMMDD) tarih boyutu.
dim_customer (SCD Type 2): Müşterilerin taşınma geçmişini korumak için valid_from, valid_to ve is_current alanlarıyla tasarlanmış yavaş değişen boyut tablosu.
⚡ 3. Sorgu Performansı ve İndeksleme (%88 Okuma Tasarrufu)

Fact tablosunda 112.650 satır üzerinde tarih ve kategori bazlı analitik bir sorgu (SET STATISTICS IO, TIME ON) ile kıyaslanmıştır:

Metrik	İndeks Öncesi (Table Scan)	İndeks Sonrası (Covering Index Seek)	Kazanım
Mantıksal Okuma (Logical Reads)	1.522 sayfa (~12 MB)	187 sayfa (~1.4 MB)	%88 Tasarruf
CPU Süresi (CPU Time)	62 ms	16 ms	%74 Hızlanma
Yürütme Süresi (Elapsed Time)	70 ms	9 ms	%87 Hızlanma

Kullanılan İndeks:

sql
CREATE NONCLUSTERED INDEX ix_fact_order_items_date_perf
ON dw.fact_order_items (order_date_key)
INCLUDE (product_key, price);
🔄 4. dbt Dönüşüm Katmanı ve Veri Kalitesi
Staging Katmanı: Ham veriyi 1:1 temizleyen ve diskte 0 MB yer kaplayan 5 adet view.
Marts Katmanı: Analize hazır fiziksel tablolar ve büyük veri verimliliği sağlayan Incremental (Artımlı) fact_order_items modeli.
Veri Kalitesi Testleri: 9 adet otomatik veri kalitesi testi (not_null, unique, relationships / referans bütünlüğü) 0.88 saniyede %100 PASS ile tamamlanmıştır.
dbt Lineage Graph (Soy Ağacı)

Preview unavailable

📊 5. Power BI Dashboard ve İş Sorularına Cevaplar

Preview unavailable

Aylık Ciro: 2016'dan 2018'e istikrarlı büyüme; Kasım 2017 Black Friday döneminde rekor günlük ciro.
Top Kategoriler: En çok ciro getiren kategoriler sırasıyla Health & Beauty (1.25M R$), Watches & Gifts (1.20M R$) ve Bed Bath Table (1.03M R$).
Eyalet Dağılımı: SP (Sao Paulo) eyaleti, tüm siparişlerin %40'ından fazlasını tek başına oluşturmaktadır.
Ortalama Teslimat Süresi: Brezilya genelinde ortalama teslimat süresi 12,41 gündür.
🚀 6. Projeyi Çalıştırma (Quickstart with Docker)

Projeyi herhangi bir bilgisayarda (Mac, Linux, Windows) sıfırdan tek komutla çalıştırmak için:

bash
# 1. Depoyu klonlayın
git clone https://github.com/HelenAktas7/olist-data-warehouse.git
cd olist-data-warehouse
# 2. SQL Server konteynerini başlatın
docker compose up -d
# 3. Sanal ortamı kurun ve bağımlılıkları yükleyin
python -m venv .venv
.\.venv\Scripts\Activate
pip install -r requirements.txt
# 4. Ham CSV verilerini yükleyin
python load_raw.py
# 5. dbt dönüşümlerini ve testlerini koşturun
dbt run --target docker
dbt test --target docker