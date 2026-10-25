-- Run in the database containing dbo.HDB_Raw.
-- Read-only check: 4 ROOM, 2021-2025, floor area 70-176 m2.
-- Observed: 57843 total, 550000 median, 37864 within SGD 600000.
WITH Filtered AS (
    SELECT TRY_CONVERT(decimal(18, 2), resale_price) AS price
    FROM dbo.HDB_Raw
    WHERE UPPER(LTRIM(RTRIM(flat_type))) = '4 ROOM'
      AND TRY_CONVERT(date, CONCAT(LEFT([month], 7), '-01')) >= '20210101'
      AND TRY_CONVERT(date, CONCAT(LEFT([month], 7), '-01')) < '20260101'
      AND TRY_CONVERT(decimal(10, 2), floor_area_sqm) BETWEEN 70 AND 176
),
Results AS (
    SELECT price,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price) OVER () AS median_price
    FROM Filtered
    WHERE price IS NOT NULL
)
SELECT COUNT(*) AS Total_Transactions,
       MAX(median_price) AS Median_Resale_Price,
       SUM(CASE WHEN price <= 600000 THEN 1 ELSE 0 END) AS Transactions_Within_600000
FROM Results;
