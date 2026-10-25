-- Prerequisite: import the published HDB CSV into Portfolio.dbo.HDB_Raw.
-- Running this script creates or updates dbo.vHDB for the Singapore 4-room analysis.
USE Portfolio;
GO

CREATE OR ALTER VIEW dbo.vHDB AS
SELECT
    [month],
    CAST(LEFT([month], 4) AS int) AS sale_year,
    town,
    resale_price,
    floor_area_sqm,
    flat_model,
    storey_range
FROM dbo.HDB_Raw
WHERE [month] >= '2021-01'
  AND [month] < '2026-01'
  AND flat_type = '4 ROOM';
GO

-- Scope check: expected reference import has 57,843 transactions.
SELECT
    COUNT(*) AS Transactions,
    MIN([month]) AS FirstMonth,
    MAX([month]) AS LastMonth
FROM dbo.vHDB;
GO
