USE olist;
GO

-- Eğer fact_order_items tablosu bu tabloya bağlıysa DROP hata verebilir,
-- bu yüzden IF NOT EXISTS ile güvenli oluşturuyoruz.
IF OBJECT_ID('dw.dim_date', 'U') IS NULL
BEGIN
    CREATE TABLE dw.dim_date (
        date_key       INT PRIMARY KEY,
        full_date      DATE NOT NULL,
        year_number    INT NOT NULL,
        quarter_number INT NOT NULL,
        month_number   INT NOT NULL,
        month_name     VARCHAR(20) NOT NULL,
        day_of_month   INT NOT NULL,
        day_of_week    INT NOT NULL,
        day_name       VARCHAR(20) NOT NULL,
        is_weekend     BIT NOT NULL
    );
END
GO

-- Tablo boşsa 2016-01-01 ile 2018-12-31 arasını otomatik üretip doldurur
IF NOT EXISTS (SELECT 1 FROM dw.dim_date)
BEGIN
    SET LANGUAGE English;
    SET DATEFIRST 1; -- Pazartesi = 1, Pazar = 7

    WITH DateSequence AS (
        SELECT CAST('2016-01-01' AS DATE) AS d
        UNION ALL
        SELECT DATEADD(DAY, 1, d)
        FROM DateSequence
        WHERE d < '2018-12-31'
    )
    INSERT INTO dw.dim_date (
        date_key,
        full_date,
        year_number,
        quarter_number,
        month_number,
        month_name,
        day_of_month,
        day_of_week,
        day_name,
        is_weekend
    )
    SELECT
        YEAR(d) * 10000 + MONTH(d) * 100 + DAY(d) AS date_key,
        d AS full_date,
        YEAR(d) AS year_number,
        DATEPART(QUARTER, d) AS quarter_number,
        MONTH(d) AS month_number,
        DATENAME(MONTH, d) AS month_name,
        DAY(d) AS day_of_month,
        DATEPART(WEEKDAY, d) AS day_of_week,
        DATENAME(WEEKDAY, d) AS day_name,
        CASE WHEN DATEPART(WEEKDAY, d) IN (6, 7) THEN 1 ELSE 0 END AS is_weekend
    FROM DateSequence
    OPTION (MAXRECURSION 0);
END
GO