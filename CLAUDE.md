# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A university (SLIIT IT3101) data warehouse project: T-SQL scripts that build an enterprise data warehouse (`AdventureWorks_DW`) on Microsoft SQL Server from the `AdventureWorks2022` OLTP database plus CSV/JSON/XML files, and a Power BI dashboard on top of it. There is no build system, test runner, or linter. The deliverables are the numbered SQL scripts in [Scripts/](Scripts/), the Power BI file in [Dashboard/](Dashboard/), and the final report (`DWBI_2026-DS-15_FinalReport.pdf`; the `.docx` source is kept locally and git-ignored).

## Running the pipeline

Scripts are meant to be run **in order, each in one SSMS query window (single session)**, against a SQL Server instance that already has `AdventureWorks2022` restored. There is no wrapper script. With `sqlcmd` the equivalent is `sqlcmd -S <server> -E -i Scripts/0N_*.sql`, one file per invocation.

| Script | Database | Purpose |
|---|---|---|
| `01_Structure_Establishment.sql` | creates `AdventureWorks_DW` | Database, schemas, ETL control objects, all EDW dimension and fact tables, FK indexes. **Not re-runnable**: it uses plain `CREATE DATABASE` / `CREATE TABLE`, so drop the DB first to rebuild. |
| `02_Format_Differentiator.sql` | `AdventureWorks2022` | Queries whose result grids are saved by hand from SSMS as the file sources: `Product.csv`, `ProductSubCategory.csv`, `ProductCategory.csv`, `SalesTerritory.json` (`FOR JSON`), `Sales.SalesOffers.xml` (`FOR XML`). These files are **not in the repo**. |
| `03_Extraction.sql` | DW | Drops and recreates every `stg.*` table, then loads files via `BULK INSERT` / `OPENROWSET` + `OPENJSON` / XML `.nodes()`, and relational tables via cross-database `INSERT ... SELECT FROM AdventureWorks2022...`. |
| `04_Data_Profiling.sql` | DW | Read-only profiling of the staging data (missing values, damaged dates, trailing spaces, coded values). |
| `05_Transform_and_Load.sql` | DW | Transform staging into `edw.*` dimensions, then facts. |
| `06_Data_Mart_Establishment.sql` | DW | `CREATE OR ALTER VIEW` data marts over `edw.*`. Safe to re-run. |
| `07_Validation_and_Reconciliation.sql` | DW | Writes 38 checks to `etl.DataQualityResult` and shows this run's results, FAILs first. Re-runnable (appends rows). |

**Source file path:** script 03 reads files from `etl.PipelineConfig` where `ConfigKey = 'SourceFilePath'` (seeded in script 01 with a developer's Windows path; it must end with a backslash). Update that row rather than hard-coding paths in the ETL. The SQL Server service account needs read access to the folder.

## Architecture

Layers map to schemas in `AdventureWorks_DW`:

- `stg` — raw landing. File-sourced staging columns are all `NVARCHAR` so dirty values never fail the load; typing and cleansing happen in script 05 with `TRY_CONVERT` and `etl.fn_CleanText` (trims and turns `''` / `'NULL'` into real NULL).
- `edw` — galaxy schema: 13 conformed dimensions and 8 facts (`FactSales` holds both channels via `SalesChannel` = `Internet`/`Reseller`; also SalesReason (factless), SalesQuota, Purchases, ProductionWorkOrder, InventoryTransaction, InventorySnapshot, CurrencyRate).
- `etl` — `PipelineConfig`, `ExecutionLog` (written via `etl.usp_LogStep`), `DataQualityResult` (its `Status` is a computed PASS/FAIL column with a rounding tolerance for money totals).
- `dm_internet_sales`, `dm_reseller_sales`, `dm_purchasing`, `dm_production`, `dm_inventory` — dependent data marts made **only of views** over `edw`. Mart dimension views are filtered to members that appear in that mart's facts (plus the `-1` Unknown row), so Power BI slicers stay clean.

The Power BI model (`Dashboard/*.pbix`) imports `dm_internet_sales` plus `FactSales` (both channels, for the Enterprise Sales Overview page), `DimReseller`, `DimEmployee` and `DimSalesReason`. Its DAX measures live in a `_Measures` table, and copies are embedded in the pbix as `DAXQueries/Query 1.dax` and `TMDLScripts/Script 1.tmdl` (UTF-16). Renaming or removing a column in a mart view or in `FactSales` breaks the dashboard. The model is a ROLAP/VertiPaq design: there is no SSAS cube.

### Conventions in script 05 that new code must follow

- **Section pattern:** every dimension or fact is one numbered section with three `GO`-separated batches: (1) `SELECT ... INTO #X_Transform` doing all cleansing, with `ROW_NUMBER() ... AS rn` for de-duplication; (2) ad-hoc `VERIFYING` SELECTs against the temp table; (3) a `BEGIN TRY / BEGIN TRANSACTION` load that logs with `etl.usp_LogStep`, and in `CATCH` rolls back, logs `Failed`, `RAISERROR`s and then runs `SET NOEXEC ON`.
- `SET NOEXEC ON` is the pipeline's stop mechanism: once a step fails, every later batch is skipped so facts never load on a broken dimension. The final batch runs `SET NOEXEC OFF`. Because of this and the `#temp` tables that span batches, script 05 must run as one session from top to bottom.
- **Unknown members:** every dimension has a `-1` row (inserted with `IDENTITY_INSERT` in step 1). Fact lookups use `ISNULL(dim.Key, -1)` rather than dropping rows. Script 07 then counts `-1` fallbacks, expecting 0.
- **Dimensions are SCD Type 1** via `MERGE` on the alternate (business) key, updating only when `EXISTS (SELECT src... EXCEPT SELECT tgt...)` detects a change, and setting `ETLUpdateDate`.
- **Facts are insert-only and idempotent:** `INSERT ... WHERE rn = 1 AND NOT EXISTS (same grain in target)`. Each fact has a `UNIQUE` grain constraint (e.g. `FactSales` on `SalesOrderNumber, SalesOrderLineNumber`).
- Date keys are `YYYYMMDD` integers (`CONVERT(CHAR(8), date, 112)`). `DimDate` is generated, not extracted, and needs `SET LANGUAGE us_english; SET DATEFIRST 7;` (set at the top of 05).
- `FactSales` derives measures rather than copying `LineTotal`: header `TaxAmt`/`Freight` are allocated to lines in proportion to `LineTotal`, and `ProductStandardCost` comes from the `ProductCostHistory` row valid on the order date. Script 07 reconciles these money totals back to the source.

### Validation

Script 07 compares the EDW directly against `AdventureWorks2022` (row counts and money totals), plus uniqueness, Unknown-member integrity and completeness checks. When you add a fact, dimension or business rule, add the matching rows to 07 in the same `INSERT INTO etl.DataQualityResult ... UNION ALL` style. Dimension counts are expected to be source count + 1 (the Unknown member).
