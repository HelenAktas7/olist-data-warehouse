{{ config(materialized='table') }}

WITH E1(N) AS (
    SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1
    UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1
),
E2(N) AS (SELECT 1 FROM E1 a, E1 b),
E4(N) AS (SELECT 1 FROM E2 a, E2 b),
cteTally(N) AS (
    SELECT TOP 1096 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 FROM E4
),
DateSequence AS (
    SELECT DATEADD(day, N, '2016-01-01') AS d FROM cteTally
)

SELECT
    YEAR(d) * 10000 + MONTH(d) * 100 + DAY(d) AS date_key,
    CAST(d AS DATE) AS full_date,
    YEAR(d) AS year_number,
    DATEPART(QUARTER, d) AS quarter_number,
    MONTH(d) AS month_number,
    DATENAME(MONTH, d) AS month_name,
    DAY(d) AS day_of_month,
    DATEPART(WEEKDAY, d) AS day_of_week,
    DATENAME(WEEKDAY, d) AS day_name,
    CASE WHEN DATEPART(WEEKDAY, d) IN (6, 7) THEN 1 ELSE 0 END AS is_weekend
FROM DateSequence