"""Olist CSV dosyalarini SQL Server'daki 'raw' semasina HAM (metin) olarak yukler."""
import logging
from pathlib import Path
from urllib.parse import quote_plus

import pandas as pd
from sqlalchemy import create_engine, text
from sqlalchemy.types import Unicode

SERVER = r"HELEN\SQLEXPRESS04"
DATABASE = "olist"
DRIVER = "ODBC Driver 18 for SQL Server"
DATA_DIR = Path(__file__).parent / "data" / "raw"

# CSV dosyasi -> raw semasindaki tablo adi
FILES = {
    "olist_orders_dataset.csv": "orders",
    "olist_order_items_dataset.csv": "order_items",
    "olist_customers_dataset.csv": "customers",
    "olist_products_dataset.csv": "products",
    "olist_sellers_dataset.csv": "sellers",
    "product_category_name_translation.csv": "category_name_translation",
}

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("load_raw")


def get_engine():
    conn_str = (
        f"DRIVER={{{DRIVER}}};SERVER={SERVER};DATABASE={DATABASE};"
        "Trusted_Connection=yes;TrustServerCertificate=yes;"
    )
    url = "mssql+pyodbc:///?odbc_connect=" + quote_plus(conn_str)
    return create_engine(url, fast_executemany=True)


def load_table(engine, csv_name, table):
    path = DATA_DIR / csv_name
    if not path.exists():
        raise FileNotFoundError(f"CSV bulunamadi: {path}")

    # dtype=str: her sutunu METIN oku (99.90 oldugu gibi kalsin, sayiya cevirme)
    # keep_default_na=False: bos hucreler '' olarak kalsin
    df = pd.read_csv(
        path, dtype=str, keep_default_na=False, na_values=[], encoding="utf-8-sig"
    )
    log.info("%s okundu: %d satir, %d sutun", csv_name, len(df), len(df.columns))

    # if_exists='replace': tablo varsa silip bastan olusturur (tekrar calistirilabilir)
    df.to_sql(
        table,
        engine,
        schema="raw",
        if_exists="replace",
        index=False,
        dtype={col: Unicode(255) for col in df.columns},
        chunksize=5000,
    )

    # Kontrol: tabloya yazilan satir sayisi, dosyadaki satir sayisina esit mi?
    with engine.connect() as conn:
        count = conn.execute(text(f"SELECT COUNT(*) FROM raw.{table}")).scalar()
    if count != len(df):
        raise ValueError(f"raw.{table}: dosyada {len(df)}, tabloda {count} satir")
    log.info("raw.%s yuklendi: %d satir (dosya ile ayni)", table, count)


def main():
    engine = get_engine()
    for csv_name, table in FILES.items():
        load_table(engine, csv_name, table)
    log.info("Tum tablolar yuklendi.")


if __name__ == "__main__":
    main()