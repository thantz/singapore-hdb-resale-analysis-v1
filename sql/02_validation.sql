-- Read-only reconciliation queries; run after 01_analysis_view.sql.
USE Portfolio;
GO

-- Overall count and median; expected: 57,843 and SGD 550,000.
SELECT DISTINCT
    COUNT(*) OVER () AS Transactions,
    CAST(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY resale_price) OVER () AS decimal(14, 2)) AS MedianPrice
FROM dbo.vHDB;
GO

-- Annual count and median; compare with the Market Overview page.
SELECT DISTINCT
    sale_year,
    COUNT(*) OVER (PARTITION BY sale_year) AS Transactions,
    CAST(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY resale_price) OVER (PARTITION BY sale_year) AS decimal(14, 2)) AS MedianPrice
FROM dbo.vHDB
ORDER BY sale_year;
GO

-- Median transaction-level price per square metre by town.
WITH UnitPrices AS (
    SELECT town, resale_price / NULLIF(floor_area_sqm, 0) AS price_per_sqm
    FROM dbo.vHDB
    WHERE floor_area_sqm > 0 AND resale_price IS NOT NULL
)
SELECT DISTINCT
    town,
    CAST(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price_per_sqm) OVER (PARTITION BY town) AS decimal(14, 2)) AS MedianPricePerSqm
FROM UnitPrices
ORDER BY MedianPricePerSqm DESC;
GO

-- Historical transactions at or below an example budget, matching the Explorer
-- page when Town=All, Year=All, and the full floor-area range is selected.
-- Budget is a What-if parameter; it does not represent current listings.
WITH Eligible AS (
    SELECT resale_price
    FROM dbo.vHDB
    WHERE floor_area_sqm >= 70
      AND floor_area_sqm <= 176
)
SELECT
    SUM(CASE WHEN resale_price <= 700000 THEN 1 ELSE 0 END) AS TransactionsWithinBudget,
    CAST(100.0 * SUM(CASE WHEN resale_price <= 700000 THEN 1 ELSE 0 END)
         / NULLIF(COUNT(*), 0) AS decimal(5, 1)) AS ShareWithinBudget
FROM Eligible;
GO
