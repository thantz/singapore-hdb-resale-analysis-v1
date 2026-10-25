# Singapore 4-Room HDB Resale Analysis

A portfolio project using Microsoft SQL Server and Power BI to examine Singapore 4-room HDB resale transactions from January 2021 through December 2025. The report has three pages: **Market Overview**, **Town & Budget Explorer**, and **Flat Profile & Price Drivers**.

## Analysis questions

- How did the median resale price and transaction count change between 2021 and 2025?
- How do town-level resale prices compare, including median price per square metre?
- How many historical transactions were at or below a selected budget, and what share of the filtered transactions did they represent?

- How do median resale prices vary across floor areas, flat models, and storey ranges?

## Key findings

The reference data contains **57,843 transactions** and has an overall transaction-level median resale price of **SGD 550,000**. Annual median resale price rose from SGD 470,000 in 2021 to SGD 630,000 in 2025 (34.0%). Transaction count fell from 12,346 to 10,843 (12.2%) over those endpoint years.

| Year | Transactions | Median resale price (SGD) |
| --- | ---: | ---: |
| 2021 | 12,346 | 470,000 |
| 2022 | 11,309 | 515,000 |
| 2023 | 11,357 | 550,000 |
| 2024 | 11,988 | 590,000 |
| 2025 | 10,843 | 630,000 |

Annual medians are calculated independently from each year's transactions; the overall median is calculated across all transactions. These descriptive changes do not track the same flats over time.

## Data source and scope

- **Publisher:** Housing & Development Board (HDB), via data.gov.sg.
- **Dataset:** [Resale flat prices based on registration date from January 2017 onwards](https://data.gov.sg/datasets/d_8b84c4ee58e3cfc0ece0d773c8ca6abc/view).
- **Included rows:** `flat_type = '4 ROOM'`, `month >= '2021-01'` and `month < '2026-01'`.
- **SQL source table:** `Portfolio.dbo.HDB_Raw`; analysis view: `Portfolio.dbo.vHDB`.
- **Currency:** nominal Singapore dollars (SGD).

The reference totals reflect the CSV import used for this project. The publisher may revise historical records, which can change totals.

## Report pages

### 1. Market Overview

- KPI cards: Transactions and Median resale price (SGD).
- Monthly median resale price line chart.
- Median resale price by town bar chart.
- Year dropdown slicer.

### 2. Town & Budget Explorer

- Town and Year dropdown slicers.
- Floor area (m²) range slicer.
- Budget range slider, from SGD 0 to SGD 2,000,000 in SGD 10,000 increments; the initial selection is SGD 600,000.
- Cards for Transactions Within Budget, Median price per m² within budget (SGD), and Share Within Budget.
- Median resale price per m² by town chart, with transaction count and median resale price available in tooltips.

The disconnected Budget parameter applies `resale_price <= selected budget` to the transaction-count and median-price-per-m² budget measures. Share Within Budget divides the budget count by all eligible transactions. Town, Year, and floor-area filters define the eligible population.

The town chart provides market context across all budgets within the selected Town, Year, and floor-area filters. Changing Budget does not change this chart. Its subtitle should explicitly say “All budgets”.

### 3. Flat Profile & Price Drivers

- Town and Year dropdown slicers.
- Scatter chart showing median resale price for each distinct floor area.
- Median resale price by flat model bar chart.
- Median resale price by storey range bar chart.

Each scatter point represents a floor-area group, rather than an individual transaction. Comparisons describe price patterns; they do not establish that one characteristic causes a price difference. Read group medians alongside transaction counts, especially for rare flat models and floor areas.

## SQL and Power BI workflow

1. Download the source CSV from the dataset page and import it into SQL Server as `Portfolio.dbo.HDB_Raw`.
2. Keep `month` as text in `YYYY-MM` format; load `resale_price` and `floor_area_sqm` as numeric fields.
3. Run `sql/01_analysis_view.sql` to create `dbo.vHDB` with the analysis period, flat type, and required columns.
4. Run `sql/02_validation.sql` and `sql/03_Validate_PowerBI.sql`; compare results with the report using matching filters.
5. In Power BI Desktop, connect to SQL Server in Import mode and load `dbo.vHDB`; name the model table `HDB`.
6. Create the measures and date column below. Create the Budget numeric What-if parameter with min 0, max 2,000,000, increment 10,000, default 600,000, and add its slicer.
7. Build all three report pages and confirm the slicers and cards respond as described.

## Core DAX expressions

**Transactions**
```dax
Transactions = COUNTROWS('HDB')
```

**Median Price**
```dax
Median Price = MEDIAN('HDB'[resale_price])
```

**Median Price per sqm** (median of each transaction's resale price divided by its floor area)
```dax
Median Price per sqm =
MEDIANX(
    FILTER(
        'HDB',
        'HDB'[floor_area_sqm] > 0
            && NOT ISBLANK('HDB'[resale_price])
    ),
    DIVIDE('HDB'[resale_price], 'HDB'[floor_area_sqm])
)
```

**Median Price per sqm Within Budget**
```dax
Median Price per sqm Within Budget =
VAR SelectedBudget = SELECTEDVALUE('Budget'[Budget], 600000)
RETURN
    MEDIANX(
        FILTER(
            'HDB',
            'HDB'[floor_area_sqm] > 0
                && NOT ISBLANK('HDB'[resale_price])
                && 'HDB'[resale_price] <= SelectedBudget
        ),
        DIVIDE('HDB'[resale_price], 'HDB'[floor_area_sqm])
    )
```

Use this measure in the budget page's median-price-per-m² card. Retain the original Median Price per sqm measure for the town chart. If no transactions qualify, the median is blank.

**Transactions Within Budget**
```dax
Transactions Within Budget =
VAR BudgetAmount = SELECTEDVALUE('Budget'[Budget], 600000)
RETURN
    COALESCE(
        CALCULATE(
            [Transactions],
            KEEPFILTERS('HDB'[resale_price] <= BudgetAmount)
        ),
        0
    )
```

**Share Within Budget**
```dax
Share Within Budget =
DIVIDE([Transactions Within Budget], [Transactions], 0)
```

Format Share Within Budget as a percentage. Keep full SGD values visible on the Market Overview KPI cards (display units: None).

**Month Date calculated column**
```dax
Month Date =
DATE(
    VALUE(LEFT('HDB'[month], 4)),
    VALUE(RIGHT('HDB'[month], 2)),
    1
)
```

Use `Month Date` itself on the monthly line chart, not its automatic date hierarchy; set the axis to continuous.

## Validation and example behavior

The executed SQL check matched Power BI for 4-room transactions from 2021–2025 with floor area between 70 and 176 m²:

- Total transactions: **57,843**
- Overall median resale price: **SGD 550,000**
- Transactions at or below SGD 600,000: **37,864**

With Town and Year set to All and floor area set to 70–176 m², Power BI showed:

| Budget (SGD) | Transactions within budget | Share within budget | Median price per m² within budget (SGD) |
| ---: | ---: | ---: | ---: |
| 600,000 | 37,864 | 65.5% | 5,286 |
| 700,000 | 47,885 | 82.8% | 5,556 |

Budget changes were checked in Power BI. The town chart remains unchanged because it uses the original measure across all budgets. Town and Year slicer changes were also observed on the Flat Profile & Price Drivers page.

The executed SQL check validates the overall count, overall median resale price, and transaction count within SGD 600,000 under the stated filters. It does not independently validate every visual or measure. Annual figures above are retained reference findings; they were not revalidated in this update.

Reference figures apply to the imported dataset and can change if historical records are revised.

## Interpretation and limitations

This is a descriptive analysis of recorded transactions. Annual and town medians reflect the mix of flats sold, including location, floor area, storey, flat model, and remaining lease. The 34.0% price change compares annual transaction medians; estimating appreciation for a comparable flat would require controlling for these characteristics. Town medians should be read alongside transaction counts. Prices are nominal and are not adjusted for inflation. The budget feature describes past sales within a price ceiling, not current homes for sale or a measure of mortgage affordability.

## Included files

- `report/Singapore_HDB_Analysis_Version2.pbix`: supplied Power BI Desktop report.
- `report/report-overview.png`: updated Market Overview screenshot, Year = All.
- `report/town-budget-explorer.png`: updated Explorer screenshot, Town/Year = All, floor area 70–176 m², budget SGD 600,000.
- `report/flat-profile-price-drivers.png`: supplied Flat Profile & Price Drivers screenshot.
- `sql/01_analysis_view.sql`: analysis view definition.
- `sql/02_validation.sql`: overall, annual, town and budget validation queries.
- `sql/03_Validate_PowerBI.sql`: executed reference reconciliation query.
- `report/REPORT_NOTES.txt`: report usage and preview notes.

## Opening the report

Extract the ZIP and open `report/Singapore_HDB_Analysis_Version2.pbix` in Power BI Desktop. Refresh requires SQL Server access and the source tables/view described above; configure the server and database for your own environment.

The PBIX is included unchanged. Its ZIP structure was checked, but it was not opened or refreshed in Power BI Desktop during packaging. Screenshots are user-supplied previews, not exports generated from the PBIX during this check.

The Explorer screenshot shows 37,864 transactions within budget, SGD 5,286 median price per m² within budget, and 65.5% share. Its title selection border remains visible. Its card omits the SGD label and its town-chart subtitle does not yet explicitly say “All budgets”; the chart covers all budgets as explained above.
