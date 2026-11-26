USE AdventureWorks_DW;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET LANGUAGE us_english;   -- English day / month names in DimDate
SET DATEFIRST 7;
SET NOEXEC OFF;
GO

/*==============================================================================
    0. CLEAN UP TEMPORARY TABLES
==============================================================================*/
DROP TABLE IF EXISTS #DimDate_Transform, #DimTerritory_Transform, #DimPromotion_Transform, #DimSalesReason_Transform,
                     #DimCurrency_Transform, #DimShipMethod_Transform, #DimLocation_Transform, #DimScrapReason_Transform,
                     #DimProduct_Transform, #DimCustomer_Transform, #DimReseller_Transform, #DimEmployee_Transform,
                     #DimVendor_Transform, #FactSales_Transform, #FactSalesReason_Transform, #FactSalesQuota_Transform,
                     #FactPurchases_Transform, #FactProduction_Transform, #FactInvTxn_Transform, #FactInvSnap_Transform,
                     #FactCurrencyRate_Transform;
GO


/*==============================================================================
    1. UNKNOWN MEMBERS (-1) FOR EVERY DIMENSION
==============================================================================*/
PRINT 'STEP 1: Creating Unknown members...';

BEGIN TRY
    BEGIN TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM edw.DimDate WHERE DateKey = -1)
        INSERT INTO edw.DimDate (DateKey, FullDate, DayNumberOfWeek, EnglishDayNameOfWeek, DayNumberOfMonth, DayNumberOfYear,
                                 WeekNumberOfYear, EnglishMonthName, MonthNumberOfYear, CalendarQuarter, CalendarSemester,
                                 CalendarYear, YearMonthKey, MonthYearLabel, QuarterLabel, FiscalQuarter, FiscalYear, IsWeekend)
        VALUES (-1, '19000101', 0, N'Unknown', 0, 0, 0, N'Unknown', 0, 0, 0, 0, 0, N'Unknown', N'Unknown', 0, 0, 0);

    IF NOT EXISTS (SELECT 1 FROM edw.DimTerritory WHERE TerritoryKey = -1)
    BEGIN
        SET IDENTITY_INSERT edw.DimTerritory ON;
        INSERT INTO edw.DimTerritory (TerritoryKey, TerritoryAlternateKey, RegionName, CountryRegionCode, TerritoryGroup)
        VALUES (-1, -1, N'Unknown', N'UNK', N'Unknown');
        SET IDENTITY_INSERT edw.DimTerritory OFF;
    END

    IF NOT EXISTS (SELECT 1 FROM edw.DimProduct WHERE ProductKey = -1)
    BEGIN
        SET IDENTITY_INSERT edw.DimProduct ON;
        INSERT INTO edw.DimProduct (ProductKey, ProductAlternateKey, ProductName, Color, StandardCost, ListPrice,
                                    ProductLine, Class, Style, ProductModelName, SubcategoryName, CategoryName)
        VALUES (-1, -1, N'Unknown', N'Unknown', 0, 0, N'Unknown', N'Unknown', N'Unknown', N'Unknown', N'Unknown', N'Unknown');
        SET IDENTITY_INSERT edw.DimProduct OFF;
    END

    IF NOT EXISTS (SELECT 1 FROM edw.DimCustomer WHERE CustomerKey = -1)
    BEGIN
        SET IDENTITY_INSERT edw.DimCustomer ON;
        INSERT INTO edw.DimCustomer (CustomerKey, CustomerAlternateKey, FirstName, LastName, FullName, AgeGroup, Gender,
                                     MaritalStatus, YearlyIncome, Education, Occupation, CommuteDistance, EmailPromotion,
                                     EmailPromotionDesc, City, StateProvinceName, CountryRegionCode, CountryRegionName)
        VALUES (-1, -1, N'Unknown', N'Unknown', N'Unknown / Not applicable', N'Unknown', N'Unknown', N'Unknown', N'Unknown',
                N'Unknown', N'Unknown', N'Unknown', 0, N'Unknown', N'Unknown', N'Unknown', N'UNK', N'Unknown');
        SET IDENTITY_INSERT edw.DimCustomer OFF;
    END

    IF NOT EXISTS (SELECT 1 FROM edw.DimReseller WHERE ResellerKey = -1)
    BEGIN
        SET IDENTITY_INSERT edw.DimReseller ON;
        INSERT INTO edw.DimReseller (ResellerKey, ResellerAlternateKey, ResellerName, BusinessType, Specialty,
                                     City, StateProvinceName, CountryRegionCode, CountryRegionName)
        VALUES (-1, -1, N'Unknown / Not applicable', N'Unknown', N'Unknown', N'Unknown', N'Unknown', N'UNK', N'Unknown');
        SET IDENTITY_INSERT edw.DimReseller OFF;
    END

    IF NOT EXISTS (SELECT 1 FROM edw.DimEmployee WHERE EmployeeKey = -1)
    BEGIN
        SET IDENTITY_INSERT edw.DimEmployee ON;
        INSERT INTO edw.DimEmployee (EmployeeKey, EmployeeAlternateKey, FirstName, LastName, FullName, JobTitle, DepartmentName,
                                     DepartmentGroupName, ShiftName, Gender, MaritalStatus, IsSalesPerson, SalesTerritoryKey)
        VALUES (-1, -1, N'Unknown', N'Unknown', N'Unknown / No sales person', N'Unknown', N'Unknown', N'Unknown', N'Unknown',
                N'Unknown', N'Unknown', 0, -1);
        SET IDENTITY_INSERT edw.DimEmployee OFF;
    END

    IF NOT EXISTS (SELECT 1 FROM edw.DimPromotion WHERE PromotionKey = -1)
    BEGIN
        SET IDENTITY_INSERT edw.DimPromotion ON;
        INSERT INTO edw.DimPromotion (PromotionKey, PromotionAlternateKey, PromotionName, DiscountPct, PromotionType, PromotionCategory)
        VALUES (-1, -1, N'Unknown', 0, N'Unknown', N'Unknown');
        SET IDENTITY_INSERT edw.DimPromotion OFF;
    END

    IF NOT EXISTS (SELECT 1 FROM edw.DimSalesReason WHERE SalesReasonKey = -1)
    BEGIN
        SET IDENTITY_INSERT edw.DimSalesReason ON;
        INSERT INTO edw.DimSalesReason (SalesReasonKey, SalesReasonAlternateKey, SalesReasonName, SalesReasonType)
        VALUES (-1, -1, N'Unknown', N'Unknown');
        SET IDENTITY_INSERT edw.DimSalesReason OFF;
    END

    IF NOT EXISTS (SELECT 1 FROM edw.DimVendor WHERE VendorKey = -1)
    BEGIN
        SET IDENTITY_INSERT edw.DimVendor ON;
        INSERT INTO edw.DimVendor (VendorKey, VendorAlternateKey, VendorName, CreditRatingDesc, City, StateProvinceName, CountryRegionCode)
        VALUES (-1, -1, N'Unknown', N'Unknown', N'Unknown', N'Unknown', N'UNK');
        SET IDENTITY_INSERT edw.DimVendor OFF;
    END

    IF NOT EXISTS (SELECT 1 FROM edw.DimShipMethod WHERE ShipMethodKey = -1)
    BEGIN
        SET IDENTITY_INSERT edw.DimShipMethod ON;
        INSERT INTO edw.DimShipMethod (ShipMethodKey, ShipMethodAlternateKey, ShipMethodName) VALUES (-1, -1, N'Unknown');
        SET IDENTITY_INSERT edw.DimShipMethod OFF;
    END

    IF NOT EXISTS (SELECT 1 FROM edw.DimLocation WHERE LocationKey = -1)
    BEGIN
        SET IDENTITY_INSERT edw.DimLocation ON;
        INSERT INTO edw.DimLocation (LocationKey, LocationAlternateKey, LocationName) VALUES (-1, -1, N'Unknown');
        SET IDENTITY_INSERT edw.DimLocation OFF;
    END

    IF NOT EXISTS (SELECT 1 FROM edw.DimScrapReason WHERE ScrapReasonKey = -1)
    BEGIN
        SET IDENTITY_INSERT edw.DimScrapReason ON;
        INSERT INTO edw.DimScrapReason (ScrapReasonKey, ScrapReasonAlternateKey, ScrapReasonName) VALUES (-1, -1, N'No scrap / Unknown');
        SET IDENTITY_INSERT edw.DimScrapReason OFF;
    END

    IF NOT EXISTS (SELECT 1 FROM edw.DimCurrency WHERE CurrencyKey = -1)
    BEGIN
        SET IDENTITY_INSERT edw.DimCurrency ON;
        INSERT INTO edw.DimCurrency (CurrencyKey, CurrencyAlternateKey, CurrencyName) VALUES (-1, N'UNK', N'Unknown');
        SET IDENTITY_INSERT edw.DimCurrency OFF;
    END

    COMMIT TRANSACTION;
    PRINT 'Unknown members ready.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    -- IDENTITY_INSERT is a session setting and is not undone by ROLLBACK
    SET IDENTITY_INSERT edw.DimTerritory OFF;  SET IDENTITY_INSERT edw.DimProduct OFF;   SET IDENTITY_INSERT edw.DimCustomer OFF;
    SET IDENTITY_INSERT edw.DimReseller OFF;   SET IDENTITY_INSERT edw.DimEmployee OFF;  SET IDENTITY_INSERT edw.DimPromotion OFF;
    SET IDENTITY_INSERT edw.DimSalesReason OFF; SET IDENTITY_INSERT edw.DimVendor OFF;   SET IDENTITY_INSERT edw.DimShipMethod OFF;
    SET IDENTITY_INSERT edw.DimLocation OFF;   SET IDENTITY_INSERT edw.DimScrapReason OFF; SET IDENTITY_INSERT edw.DimCurrency OFF;
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(N'%s', 16, 1, @msg);   -- show the error
    SET NOEXEC ON;                   -- stop the remaining steps so facts never load on a failed dimension
END CATCH;
GO


/*==============================================================================
    2. DIM DATE  (generated calendar covering every business process)
==============================================================================*/
PRINT 'STEP 2: Transforming DimDate...';

DECLARE @MinDate DATE, @MaxDate DATE;

SELECT @MinDate = MIN(d), @MaxDate = MAX(d)
FROM
(
    SELECT CAST(OrderDate AS DATE) AS d FROM stg.SalesOrderHeader
    UNION ALL SELECT CAST(DueDate AS DATE)          FROM stg.SalesOrderHeader
    UNION ALL SELECT CAST(ShipDate AS DATE)         FROM stg.SalesOrderHeader
    UNION ALL SELECT CAST(OrderDate AS DATE)        FROM stg.PurchaseOrderHeader
    UNION ALL SELECT CAST(ShipDate AS DATE)         FROM stg.PurchaseOrderHeader
    UNION ALL SELECT CAST(DueDate AS DATE)          FROM stg.PurchaseOrderDetail
    UNION ALL SELECT CAST(StartDate AS DATE)        FROM stg.WorkOrder
    UNION ALL SELECT CAST(EndDate AS DATE)          FROM stg.WorkOrder
    UNION ALL SELECT CAST(DueDate AS DATE)          FROM stg.WorkOrder
    UNION ALL SELECT CAST(TransactionDate AS DATE)  FROM stg.TransactionHistory
    UNION ALL SELECT CAST(CurrencyRateDate AS DATE) FROM stg.CurrencyRate
    UNION ALL SELECT CAST(QuotaDate AS DATE)        FROM stg.SalesPersonQuotaHistory
    UNION ALL SELECT CAST(ModifiedDate AS DATE)     FROM stg.ProductInventory
    UNION ALL SELECT TRY_CONVERT(DATE, StartDate)   FROM stg.SpecialOffer
    UNION ALL SELECT TRY_CONVERT(DATE, EndDate)     FROM stg.SpecialOffer
) AS AllDates;

-- Whole calendar years, so year-level analysis is never cut short
SET @MinDate = DATEFROMPARTS(YEAR(@MinDate), 1, 1);
SET @MaxDate = DATEFROMPARTS(YEAR(@MaxDate), 12, 31);

WITH Numbers AS
(
    SELECT TOP (DATEDIFF(DAY, @MinDate, @MaxDate) + 1)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
),
Calendar AS
(
    SELECT DATEADD(DAY, n, @MinDate) AS dt FROM Numbers
)
SELECT
    CONVERT(INT, CONVERT(CHAR(8), dt, 112))                         AS DateKey,
    dt                                                              AS FullDate,
    CAST((DATEPART(WEEKDAY, dt) + @@DATEFIRST - 2) % 7 + 1 AS TINYINT) AS DayNumberOfWeek,
    CAST(DATENAME(WEEKDAY, dt) AS NVARCHAR(10))                     AS EnglishDayNameOfWeek,
    CAST(DAY(dt) AS TINYINT)                                        AS DayNumberOfMonth,
    CAST(DATEPART(DAYOFYEAR, dt) AS SMALLINT)                       AS DayNumberOfYear,
    CAST(DATEPART(WEEK, dt) AS TINYINT)                             AS WeekNumberOfYear,
    CAST(DATENAME(MONTH, dt) AS NVARCHAR(10))                       AS EnglishMonthName,
    CAST(MONTH(dt) AS TINYINT)                                      AS MonthNumberOfYear,
    CAST(DATEPART(QUARTER, dt) AS TINYINT)                          AS CalendarQuarter,
    CAST(CASE WHEN MONTH(dt) <= 6 THEN 1 ELSE 2 END AS TINYINT)     AS CalendarSemester,
    CAST(YEAR(dt) AS SMALLINT)                                      AS CalendarYear,
    YEAR(dt) * 100 + MONTH(dt)                                      AS YearMonthKey,
    CAST(LEFT(DATENAME(MONTH, dt), 3) + N' ' + CAST(YEAR(dt) AS NVARCHAR(4)) AS NVARCHAR(10)) AS MonthYearLabel,
    CAST(CONCAT(YEAR(dt), N' Q', DATEPART(QUARTER, dt)) AS NVARCHAR(10)) AS QuarterLabel,
    CAST(((MONTH(dt) + 5) % 12) / 3 + 1 AS TINYINT)                 AS FiscalQuarter,
    CAST(YEAR(dt) + CASE WHEN MONTH(dt) >= 7 THEN 1 ELSE 0 END AS SMALLINT) AS FiscalYear,
    CAST(CASE WHEN (DATEPART(WEEKDAY, dt) + @@DATEFIRST - 2) % 7 + 1 IN (6, 7) THEN 1 ELSE 0 END AS BIT) AS IsWeekend
INTO #DimDate_Transform
FROM Calendar;

PRINT 'DimDate transformation completed.';
GO

PRINT 'VERIFYING DimDate...';
SELECT COUNT(*) AS DaysGenerated, MIN(FullDate) AS FirstDate, MAX(FullDate) AS LastDate FROM #DimDate_Transform;
SELECT DateKey, COUNT(*) AS DuplicateCount FROM #DimDate_Transform GROUP BY DateKey HAVING COUNT(*) > 1;
GO

DECLARE @t DATETIME2(0) = SYSDATETIME(), @rc INT;
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO edw.DimDate (DateKey, FullDate, DayNumberOfWeek, EnglishDayNameOfWeek, DayNumberOfMonth, DayNumberOfYear,
                             WeekNumberOfYear, EnglishMonthName, MonthNumberOfYear, CalendarQuarter, CalendarSemester,
                             CalendarYear, YearMonthKey, MonthYearLabel, QuarterLabel, FiscalQuarter, FiscalYear, IsWeekend)
    SELECT t.DateKey, t.FullDate, t.DayNumberOfWeek, t.EnglishDayNameOfWeek, t.DayNumberOfMonth, t.DayNumberOfYear,
           t.WeekNumberOfYear, t.EnglishMonthName, t.MonthNumberOfYear, t.CalendarQuarter, t.CalendarSemester,
           t.CalendarYear, t.YearMonthKey, t.MonthYearLabel, t.QuarterLabel, t.FiscalQuarter, t.FiscalYear, t.IsWeekend
    FROM #DimDate_Transform t
    WHERE NOT EXISTS (SELECT 1 FROM edw.DimDate d WHERE d.DateKey = t.DateKey);
    SET @rc = @@ROWCOUNT;
    COMMIT TRANSACTION;
    EXEC etl.usp_LogStep N'Load Dimension', N'edw.DimDate', @rc, @t;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    DECLARE @err NVARCHAR(4000) = ERROR_MESSAGE();
    EXEC etl.usp_LogStep N'Load Dimension', N'edw.DimDate', 0, @t, N'Failed', @err;
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(N'%s', 16, 1, @msg);   -- show the error
    SET NOEXEC ON;                   -- stop the remaining steps so facts never load on a failed dimension
END CATCH;
GO


/*==============================================================================
    3. SMALL REFERENCE DIMENSIONS
==============================================================================*/
PRINT 'STEP 3: Transforming reference dimensions...';

-- 3.1 Territory (JSON)
SELECT
    TerritoryID AS TerritoryAlternateKey,
    ISNULL(etl.fn_CleanText(RegionName), N'Unknown')            AS RegionName,
    UPPER(ISNULL(etl.fn_CleanText(CountryRegionCode), N'UNK'))  AS CountryRegionCode,
    ISNULL(etl.fn_CleanText(TerritoryGroup), N'Unknown')        AS TerritoryGroup,
    ROW_NUMBER() OVER (PARTITION BY TerritoryID ORDER BY TerritoryID) AS rn
INTO #DimTerritory_Transform
FROM stg.SalesTerritory
WHERE TerritoryID IS NOT NULL;

-- 3.2 Promotion (XML)
SELECT
    SpecialOfferID AS PromotionAlternateKey,
    ISNULL(etl.fn_CleanText(Description), N'Unknown Promotion')            AS PromotionName,
    ISNULL(TRY_CONVERT(DECIMAL(10,4), etl.fn_CleanText(DiscountPct)), 0)   AS DiscountPct,
    ISNULL(etl.fn_CleanText(Type), N'Unknown')                             AS PromotionType,
    ISNULL(etl.fn_CleanText(Category), N'Unknown')                         AS PromotionCategory,
    TRY_CONVERT(DATE, etl.fn_CleanText(StartDate))                         AS StartDate,
    TRY_CONVERT(DATE, etl.fn_CleanText(EndDate))                           AS EndDate,
    ROW_NUMBER() OVER (PARTITION BY SpecialOfferID ORDER BY SpecialOfferID) AS rn
INTO #DimPromotion_Transform
FROM stg.SpecialOffer
WHERE SpecialOfferID IS NOT NULL;

-- 3.3 Sales reason
SELECT SalesReasonID AS SalesReasonAlternateKey,
       ISNULL(etl.fn_CleanText(Name), N'Unknown')       AS SalesReasonName,
       ISNULL(etl.fn_CleanText(ReasonType), N'Unknown') AS SalesReasonType,
       ROW_NUMBER() OVER (PARTITION BY SalesReasonID ORDER BY SalesReasonID) AS rn
INTO #DimSalesReason_Transform
FROM stg.SalesReason;

-- 3.4 Currency
SELECT UPPER(LTRIM(RTRIM(CurrencyCode))) AS CurrencyAlternateKey,
       ISNULL(etl.fn_CleanText(Name), N'Unknown') AS CurrencyName,
       ROW_NUMBER() OVER (PARTITION BY CurrencyCode ORDER BY CurrencyCode) AS rn
INTO #DimCurrency_Transform
FROM stg.Currency
WHERE CurrencyCode IS NOT NULL;

-- 3.5 Ship method
SELECT ShipMethodID AS ShipMethodAlternateKey,
       ISNULL(etl.fn_CleanText(Name), N'Unknown') AS ShipMethodName, ShipBase, ShipRate,
       ROW_NUMBER() OVER (PARTITION BY ShipMethodID ORDER BY ShipMethodID) AS rn
INTO #DimShipMethod_Transform
FROM stg.ShipMethod;

-- 3.6 Location
SELECT LocationID AS LocationAlternateKey,
       ISNULL(etl.fn_CleanText(Name), N'Unknown') AS LocationName, CostRate, Availability,
       ROW_NUMBER() OVER (PARTITION BY LocationID ORDER BY LocationID) AS rn
INTO #DimLocation_Transform
FROM stg.Location;

-- 3.7 Scrap reason
SELECT ScrapReasonID AS ScrapReasonAlternateKey,
       ISNULL(etl.fn_CleanText(Name), N'Unknown') AS ScrapReasonName,
       ROW_NUMBER() OVER (PARTITION BY ScrapReasonID ORDER BY ScrapReasonID) AS rn
INTO #DimScrapReason_Transform
FROM stg.ScrapReason;

PRINT 'Reference dimension transformations completed.';
GO

PRINT 'VERIFYING reference dimensions...';
-- Duplicate business keys (must return no rows)
SELECT 'Territory' AS Dim, TerritoryAlternateKey AS BusinessKey, COUNT(*) AS Cnt FROM #DimTerritory_Transform WHERE rn = 1 GROUP BY TerritoryAlternateKey HAVING COUNT(*) > 1
UNION ALL SELECT 'Promotion', PromotionAlternateKey, COUNT(*) FROM #DimPromotion_Transform WHERE rn = 1 GROUP BY PromotionAlternateKey HAVING COUNT(*) > 1;
-- Business rules on promotions (must return no rows)
SELECT * FROM #DimPromotion_Transform WHERE DiscountPct NOT BETWEEN 0 AND 1 OR StartDate > EndDate;
-- Preview
SELECT * FROM #DimTerritory_Transform WHERE rn = 1 ORDER BY TerritoryAlternateKey;
GO

DECLARE @t DATETIME2(0) = SYSDATETIME(), @rc INT;
BEGIN TRY
    BEGIN TRANSACTION;

    MERGE edw.DimTerritory AS tgt
    USING (SELECT * FROM #DimTerritory_Transform WHERE rn = 1) AS src
       ON tgt.TerritoryAlternateKey = src.TerritoryAlternateKey
    WHEN MATCHED AND EXISTS (SELECT src.RegionName, src.CountryRegionCode, src.TerritoryGroup
                             EXCEPT SELECT tgt.RegionName, tgt.CountryRegionCode, tgt.TerritoryGroup)
        THEN UPDATE SET RegionName = src.RegionName, CountryRegionCode = src.CountryRegionCode, TerritoryGroup = src.TerritoryGroup
    WHEN NOT MATCHED BY TARGET
        THEN INSERT (TerritoryAlternateKey, RegionName, CountryRegionCode, TerritoryGroup)
             VALUES (src.TerritoryAlternateKey, src.RegionName, src.CountryRegionCode, src.TerritoryGroup);
    SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Load Dimension', N'edw.DimTerritory', @rc, @t;

    SET @t = SYSDATETIME();
    MERGE edw.DimPromotion AS tgt
    USING (SELECT * FROM #DimPromotion_Transform WHERE rn = 1) AS src
       ON tgt.PromotionAlternateKey = src.PromotionAlternateKey
    WHEN MATCHED AND EXISTS (SELECT src.PromotionName, src.DiscountPct, src.PromotionType, src.PromotionCategory, src.StartDate, src.EndDate
                             EXCEPT SELECT tgt.PromotionName, tgt.DiscountPct, tgt.PromotionType, tgt.PromotionCategory, tgt.StartDate, tgt.EndDate)
        THEN UPDATE SET PromotionName = src.PromotionName, DiscountPct = src.DiscountPct, PromotionType = src.PromotionType,
                        PromotionCategory = src.PromotionCategory, StartDate = src.StartDate, EndDate = src.EndDate
    WHEN NOT MATCHED BY TARGET
        THEN INSERT (PromotionAlternateKey, PromotionName, DiscountPct, PromotionType, PromotionCategory, StartDate, EndDate)
             VALUES (src.PromotionAlternateKey, src.PromotionName, src.DiscountPct, src.PromotionType, src.PromotionCategory, src.StartDate, src.EndDate);
    SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Load Dimension', N'edw.DimPromotion', @rc, @t;

    SET @t = SYSDATETIME();
    MERGE edw.DimSalesReason AS tgt
    USING (SELECT * FROM #DimSalesReason_Transform WHERE rn = 1) AS src
       ON tgt.SalesReasonAlternateKey = src.SalesReasonAlternateKey
    WHEN MATCHED AND EXISTS (SELECT src.SalesReasonName, src.SalesReasonType EXCEPT SELECT tgt.SalesReasonName, tgt.SalesReasonType)
        THEN UPDATE SET SalesReasonName = src.SalesReasonName, SalesReasonType = src.SalesReasonType
    WHEN NOT MATCHED BY TARGET
        THEN INSERT (SalesReasonAlternateKey, SalesReasonName, SalesReasonType)
             VALUES (src.SalesReasonAlternateKey, src.SalesReasonName, src.SalesReasonType);
    SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Load Dimension', N'edw.DimSalesReason', @rc, @t;

    SET @t = SYSDATETIME();
    MERGE edw.DimCurrency AS tgt
    USING (SELECT * FROM #DimCurrency_Transform WHERE rn = 1) AS src
       ON tgt.CurrencyAlternateKey = src.CurrencyAlternateKey
    WHEN MATCHED AND tgt.CurrencyName <> src.CurrencyName
        THEN UPDATE SET CurrencyName = src.CurrencyName
    WHEN NOT MATCHED BY TARGET
        THEN INSERT (CurrencyAlternateKey, CurrencyName) VALUES (src.CurrencyAlternateKey, src.CurrencyName);
    SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Load Dimension', N'edw.DimCurrency', @rc, @t;

    SET @t = SYSDATETIME();
    MERGE edw.DimShipMethod AS tgt
    USING (SELECT * FROM #DimShipMethod_Transform WHERE rn = 1) AS src
       ON tgt.ShipMethodAlternateKey = src.ShipMethodAlternateKey
    WHEN MATCHED AND EXISTS (SELECT src.ShipMethodName, src.ShipBase, src.ShipRate EXCEPT SELECT tgt.ShipMethodName, tgt.ShipBase, tgt.ShipRate)
        THEN UPDATE SET ShipMethodName = src.ShipMethodName, ShipBase = src.ShipBase, ShipRate = src.ShipRate
    WHEN NOT MATCHED BY TARGET
        THEN INSERT (ShipMethodAlternateKey, ShipMethodName, ShipBase, ShipRate)
             VALUES (src.ShipMethodAlternateKey, src.ShipMethodName, src.ShipBase, src.ShipRate);
    SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Load Dimension', N'edw.DimShipMethod', @rc, @t;

    SET @t = SYSDATETIME();
    MERGE edw.DimLocation AS tgt
    USING (SELECT * FROM #DimLocation_Transform WHERE rn = 1) AS src
       ON tgt.LocationAlternateKey = src.LocationAlternateKey
    WHEN MATCHED AND EXISTS (SELECT src.LocationName, src.CostRate, src.Availability EXCEPT SELECT tgt.LocationName, tgt.CostRate, tgt.Availability)
        THEN UPDATE SET LocationName = src.LocationName, CostRate = src.CostRate, Availability = src.Availability
    WHEN NOT MATCHED BY TARGET
        THEN INSERT (LocationAlternateKey, LocationName, CostRate, Availability)
             VALUES (src.LocationAlternateKey, src.LocationName, src.CostRate, src.Availability);
    SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Load Dimension', N'edw.DimLocation', @rc, @t;

    SET @t = SYSDATETIME();
    MERGE edw.DimScrapReason AS tgt
    USING (SELECT * FROM #DimScrapReason_Transform WHERE rn = 1) AS src
       ON tgt.ScrapReasonAlternateKey = src.ScrapReasonAlternateKey
    WHEN MATCHED AND tgt.ScrapReasonName <> src.ScrapReasonName
        THEN UPDATE SET ScrapReasonName = src.ScrapReasonName
    WHEN NOT MATCHED BY TARGET
        THEN INSERT (ScrapReasonAlternateKey, ScrapReasonName) VALUES (src.ScrapReasonAlternateKey, src.ScrapReasonName);
    SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Load Dimension', N'edw.DimScrapReason', @rc, @t;

    COMMIT TRANSACTION;
    PRINT 'Reference dimensions loaded.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    DECLARE @err NVARCHAR(4000) = ERROR_MESSAGE();
    EXEC etl.usp_LogStep N'Load Dimension', N'Reference dimensions', 0, @t, N'Failed', @err;
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(N'%s', 16, 1, @msg);   -- show the error
    SET NOEXEC ON;                   -- stop the remaining steps so facts never load on a failed dimension
END CATCH;
GO


/*==============================================================================
    4. DIM PRODUCT 
==============================================================================*/
PRINT 'STEP 4: Transforming DimProduct...';

SELECT
    TRY_CONVERT(INT, etl.fn_CleanText(p.ProductID))                    AS ProductAlternateKey,
    etl.fn_CleanText(p.ProductNumber)                                  AS ProductNumber,
    ISNULL(etl.fn_CleanText(p.Name), N'Unknown Product')               AS ProductName,
    CASE WHEN etl.fn_CleanText(p.Color) IS NULL THEN N'Missing/Unknown'
         -- all-upper or all-lower values are standardised to proper case; mixed values (e.g. Silver/Black) are kept
         WHEN etl.fn_CleanText(p.Color) COLLATE Latin1_General_CS_AS IN (UPPER(etl.fn_CleanText(p.Color)), LOWER(etl.fn_CleanText(p.Color)))
         THEN UPPER(LEFT(etl.fn_CleanText(p.Color), 1)) + LOWER(SUBSTRING(etl.fn_CleanText(p.Color), 2, 50))
         ELSE etl.fn_CleanText(p.Color)
    END                                                                AS Color,
    etl.fn_CleanText(p.Size)                                           AS Size,
    UPPER(etl.fn_CleanText(p.SizeUnitMeasureCode))                     AS SizeUnitMeasureCode,
    TRY_CONVERT(DECIMAL(8,2), etl.fn_CleanText(p.Weight))              AS Weight,
    UPPER(etl.fn_CleanText(p.WeightUnitMeasureCode))                   AS WeightUnitMeasureCode,
    ISNULL(TRY_CONVERT(DECIMAL(19,4), etl.fn_CleanText(p.StandardCost)), 0) AS StandardCost,
    ISNULL(TRY_CONVERT(DECIMAL(19,4), etl.fn_CleanText(p.ListPrice)), 0)    AS ListPrice,
    CASE UPPER(etl.fn_CleanText(p.ProductLine))
         WHEN N'R' THEN N'Road' WHEN N'M' THEN N'Mountain' WHEN N'T' THEN N'Touring' WHEN N'S' THEN N'Standard'
         ELSE N'Not Applicable' END                                    AS ProductLine,
    CASE UPPER(etl.fn_CleanText(p.Class))
         WHEN N'H' THEN N'High' WHEN N'M' THEN N'Medium' WHEN N'L' THEN N'Low'
         ELSE N'Not Applicable' END                                    AS Class,
    CASE UPPER(etl.fn_CleanText(p.Style))
         WHEN N'W' THEN N'Womens' WHEN N'M' THEN N'Mens' WHEN N'U' THEN N'Universal'
         ELSE N'Not Applicable' END                                    AS Style,
    TRY_CONVERT(INT, etl.fn_CleanText(p.DaysToManufacture))            AS DaysToManufacture,
    TRY_CONVERT(SMALLINT, etl.fn_CleanText(p.SafetyStockLevel))        AS SafetyStockLevel,
    TRY_CONVERT(SMALLINT, etl.fn_CleanText(p.ReorderPoint))            AS ReorderPoint,
    TRY_CONVERT(BIT, etl.fn_CleanText(p.MakeFlag))                     AS MakeFlag,
    TRY_CONVERT(BIT, etl.fn_CleanText(p.FinishedGoodsFlag))            AS FinishedGoodsFlag,
    ISNULL(etl.fn_CleanText(pm.Name), N'No Model')                     AS ProductModelName,
    ISNULL(etl.fn_CleanText(ps.Name), N'Unassigned Subcategory')       AS SubcategoryName,
    ISNULL(etl.fn_CleanText(pc.Name), N'Unassigned Category')          AS CategoryName,
    ROW_NUMBER() OVER (PARTITION BY TRY_CONVERT(INT, etl.fn_CleanText(p.ProductID))
                       ORDER BY TRY_CONVERT(DATETIME, etl.fn_CleanText(p.ModifiedDate)) DESC, p.ProductNumber) AS rn
INTO #DimProduct_Transform
FROM stg.Product p
LEFT JOIN stg.ProductSubcategory ps
       ON TRY_CONVERT(INT, etl.fn_CleanText(ps.ProductSubcategoryID)) = TRY_CONVERT(INT, etl.fn_CleanText(p.ProductSubcategoryID))
LEFT JOIN stg.ProductCategory pc
       ON TRY_CONVERT(INT, etl.fn_CleanText(pc.ProductCategoryID)) = TRY_CONVERT(INT, etl.fn_CleanText(ps.ProductCategoryID))
LEFT JOIN stg.ProductModel pm
       ON pm.ProductModelID = TRY_CONVERT(INT, etl.fn_CleanText(p.ProductModelID))
WHERE TRY_CONVERT(INT, etl.fn_CleanText(p.ProductID)) IS NOT NULL;

PRINT 'DimProduct transformation completed.';
GO

PRINT 'VERIFYING DimProduct...';
SELECT * FROM #DimProduct_Transform WHERE ProductAlternateKey IS NULL OR ProductName = N'Unknown Product';   -- invalid ids / names
SELECT * FROM #DimProduct_Transform WHERE StandardCost < 0 OR ListPrice < 0;                                 -- negative money
SELECT ProductAlternateKey, COUNT(*) AS RecordCount FROM #DimProduct_Transform WHERE rn = 1
GROUP BY ProductAlternateKey HAVING COUNT(*) > 1;                                                           -- duplicates
SELECT CategoryName, COUNT(*) AS Products FROM #DimProduct_Transform WHERE rn = 1 GROUP BY CategoryName;    -- distribution
SELECT TOP 20 * FROM #DimProduct_Transform WHERE rn = 1 ORDER BY ProductAlternateKey;
GO

DECLARE @t DATETIME2(0) = SYSDATETIME(), @rc INT;
BEGIN TRY
    BEGIN TRANSACTION;
    MERGE edw.DimProduct AS tgt
    USING (SELECT * FROM #DimProduct_Transform WHERE rn = 1) AS src
       ON tgt.ProductAlternateKey = src.ProductAlternateKey
    WHEN MATCHED AND EXISTS (SELECT src.ProductNumber, src.ProductName, src.Color, src.Size, src.SizeUnitMeasureCode, src.Weight,
                                    src.WeightUnitMeasureCode, src.StandardCost, src.ListPrice, src.ProductLine, src.Class, src.Style,
                                    src.DaysToManufacture, src.SafetyStockLevel, src.ReorderPoint, src.MakeFlag, src.FinishedGoodsFlag,
                                    src.ProductModelName, src.SubcategoryName, src.CategoryName
                             EXCEPT
                             SELECT tgt.ProductNumber, tgt.ProductName, tgt.Color, tgt.Size, tgt.SizeUnitMeasureCode, tgt.Weight,
                                    tgt.WeightUnitMeasureCode, tgt.StandardCost, tgt.ListPrice, tgt.ProductLine, tgt.Class, tgt.Style,
                                    tgt.DaysToManufacture, tgt.SafetyStockLevel, tgt.ReorderPoint, tgt.MakeFlag, tgt.FinishedGoodsFlag,
                                    tgt.ProductModelName, tgt.SubcategoryName, tgt.CategoryName)
        THEN UPDATE SET ProductNumber = src.ProductNumber, ProductName = src.ProductName, Color = src.Color, Size = src.Size,
                        SizeUnitMeasureCode = src.SizeUnitMeasureCode, Weight = src.Weight, WeightUnitMeasureCode = src.WeightUnitMeasureCode,
                        StandardCost = src.StandardCost, ListPrice = src.ListPrice, ProductLine = src.ProductLine, Class = src.Class,
                        Style = src.Style, DaysToManufacture = src.DaysToManufacture, SafetyStockLevel = src.SafetyStockLevel,
                        ReorderPoint = src.ReorderPoint, MakeFlag = src.MakeFlag, FinishedGoodsFlag = src.FinishedGoodsFlag,
                        ProductModelName = src.ProductModelName, SubcategoryName = src.SubcategoryName, CategoryName = src.CategoryName,
                        ETLUpdateDate = SYSDATETIME()
    WHEN NOT MATCHED BY TARGET
        THEN INSERT (ProductAlternateKey, ProductNumber, ProductName, Color, Size, SizeUnitMeasureCode, Weight, WeightUnitMeasureCode,
                     StandardCost, ListPrice, ProductLine, Class, Style, DaysToManufacture, SafetyStockLevel, ReorderPoint,
                     MakeFlag, FinishedGoodsFlag, ProductModelName, SubcategoryName, CategoryName)
             VALUES (src.ProductAlternateKey, src.ProductNumber, src.ProductName, src.Color, src.Size, src.SizeUnitMeasureCode, src.Weight,
                     src.WeightUnitMeasureCode, src.StandardCost, src.ListPrice, src.ProductLine, src.Class, src.Style, src.DaysToManufacture,
                     src.SafetyStockLevel, src.ReorderPoint, src.MakeFlag, src.FinishedGoodsFlag, src.ProductModelName,
                     src.SubcategoryName, src.CategoryName);
    SET @rc = @@ROWCOUNT;
    COMMIT TRANSACTION;
    EXEC etl.usp_LogStep N'Load Dimension', N'edw.DimProduct', @rc, @t;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    DECLARE @err NVARCHAR(4000) = ERROR_MESSAGE();
    EXEC etl.usp_LogStep N'Load Dimension', N'edw.DimProduct', 0, @t, N'Failed', @err;
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(N'%s', 16, 1, @msg);   -- show the error
    SET NOEXEC ON;                   -- stop the remaining steps so facts never load on a failed dimension
END CATCH;
GO


/*==============================================================================
    5. DIM CUSTOMER  
==============================================================================*/
PRINT 'STEP 5: Transforming DimCustomer...';

WITH XMLNAMESPACES (N'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey' AS ns),
Geo AS
(
    SELECT bea.BusinessEntityID, a.City, a.PostalCode,
           sp.Name AS StateProvinceName, sp.CountryRegionCode, cr.Name AS CountryRegionName,
           ROW_NUMBER() OVER (PARTITION BY bea.BusinessEntityID
                              ORDER BY CASE WHEN bea.AddressTypeID = 2 THEN 0 ELSE 1 END, a.AddressID DESC) AS rn   -- 2 = Home
    FROM stg.BusinessEntityAddress bea
    JOIN stg.Address a            ON a.AddressID = bea.AddressID
    LEFT JOIN stg.StateProvince sp ON sp.StateProvinceID = a.StateProvinceID
    LEFT JOIN stg.CountryRegion cr ON cr.CountryRegionCode = sp.CountryRegionCode
),
Demo AS
(
    SELECT p.BusinessEntityID,
           TRY_CONVERT(DATE, LEFT(s.x.value('(ns:BirthDate)[1]',         'nvarchar(30)'), 10)) AS BirthDate,
           TRY_CONVERT(DATE, LEFT(s.x.value('(ns:DateFirstPurchase)[1]', 'nvarchar(30)'), 10)) AS DateFirstPurchase,
           s.x.value('(ns:MaritalStatus)[1]',        'nvarchar(5)')  AS MaritalStatus,
           s.x.value('(ns:Gender)[1]',               'nvarchar(5)')  AS Gender,
           s.x.value('(ns:YearlyIncome)[1]',         'nvarchar(30)') AS YearlyIncome,
           s.x.value('(ns:TotalChildren)[1]',        'nvarchar(5)')  AS TotalChildren,
           s.x.value('(ns:NumberChildrenAtHome)[1]', 'nvarchar(5)')  AS NumberChildrenAtHome,
           s.x.value('(ns:Education)[1]',            'nvarchar(40)') AS Education,
           s.x.value('(ns:Occupation)[1]',           'nvarchar(40)') AS Occupation,
           s.x.value('(ns:HomeOwnerFlag)[1]',        'nvarchar(5)')  AS HomeOwnerFlag,
           s.x.value('(ns:NumberCarsOwned)[1]',      'nvarchar(5)')  AS NumberCarsOwned,
           s.x.value('(ns:CommuteDistance)[1]',      'nvarchar(20)') AS CommuteDistance
    FROM stg.Person p
    CROSS APPLY (SELECT CAST(p.Demographics AS XML) AS Doc) d
    OUTER APPLY d.Doc.nodes('/ns:IndividualSurvey') AS s(x)
),
RefDate AS
(
    SELECT CAST(MAX(OrderDate) AS DATE) AS AsOfDate FROM stg.SalesOrderHeader   -- age is measured at the end of the data
)
SELECT
    c.CustomerID                                                          AS CustomerAlternateKey,
    c.AccountNumber,
    etl.fn_CleanText(p.Title)                                             AS Title,
    ISNULL(etl.fn_CleanText(p.FirstName), N'Unknown')                     AS FirstName,
    etl.fn_CleanText(p.MiddleName)                                        AS MiddleName,
    ISNULL(etl.fn_CleanText(p.LastName), N'Unknown')                      AS LastName,
    ISNULL(NULLIF(CONCAT_WS(N' ', etl.fn_CleanText(p.FirstName), etl.fn_CleanText(p.MiddleName), etl.fn_CleanText(p.LastName)), N''), N'Unknown') AS FullName,
    dm.BirthDate,
    CASE WHEN dm.BirthDate IS NULL THEN N'Unknown'
         WHEN age.Years < 35 THEN N'Under 35'
         WHEN age.Years < 50 THEN N'35 to 49'
         WHEN age.Years < 65 THEN N'50 to 64'
         ELSE N'65 and over' END                                          AS AgeGroup,
    CASE dm.Gender WHEN N'M' THEN N'Male' WHEN N'F' THEN N'Female' ELSE N'Unknown' END        AS Gender,
    CASE dm.MaritalStatus WHEN N'M' THEN N'Married' WHEN N'S' THEN N'Single' ELSE N'Unknown' END AS MaritalStatus,
    ISNULL(etl.fn_CleanText(dm.YearlyIncome), N'Unknown')                 AS YearlyIncome,
    TRY_CONVERT(TINYINT, dm.TotalChildren)                                AS TotalChildren,
    TRY_CONVERT(TINYINT, dm.NumberChildrenAtHome)                         AS NumberChildrenAtHome,
    ISNULL(etl.fn_CleanText(dm.Education), N'Unknown')                    AS Education,
    ISNULL(etl.fn_CleanText(dm.Occupation), N'Unknown')                   AS Occupation,
    TRY_CONVERT(BIT, dm.HomeOwnerFlag)                                    AS HomeOwnerFlag,
    TRY_CONVERT(TINYINT, dm.NumberCarsOwned)                              AS NumberCarsOwned,
    ISNULL(etl.fn_CleanText(dm.CommuteDistance), N'Unknown')              AS CommuteDistance,
    dm.DateFirstPurchase,
    CAST(CASE WHEN p.EmailPromotion IN (0, 1, 2) THEN p.EmailPromotion ELSE 0 END AS TINYINT) AS EmailPromotion,
    CASE WHEN p.EmailPromotion = 1 THEN N'AdventureWorks emails only'
         WHEN p.EmailPromotion = 2 THEN N'AdventureWorks and partner emails'
         ELSE N'No promotional emails' END                                AS EmailPromotionDesc,
    CAST(ISNULL(etl.fn_CleanText(g.City), N'Unknown') AS NVARCHAR(30))    AS City,
    ISNULL(etl.fn_CleanText(g.StateProvinceName), N'Unknown')             AS StateProvinceName,
    etl.fn_CleanText(g.PostalCode)                                        AS PostalCode,
    CAST(UPPER(ISNULL(etl.fn_CleanText(g.CountryRegionCode), N'UNK')) AS NVARCHAR(3)) AS CountryRegionCode,
    ISNULL(etl.fn_CleanText(g.CountryRegionName), N'Unknown')             AS CountryRegionName,
    ROW_NUMBER() OVER (PARTITION BY c.CustomerID ORDER BY c.CustomerID)   AS rn
INTO #DimCustomer_Transform
FROM stg.Customer c
JOIN stg.Person p        ON p.BusinessEntityID = c.PersonID
LEFT JOIN Demo dm        ON dm.BusinessEntityID = p.BusinessEntityID
LEFT JOIN Geo g          ON g.BusinessEntityID = p.BusinessEntityID AND g.rn = 1
CROSS JOIN RefDate r
CROSS APPLY (SELECT DATEDIFF(YEAR, dm.BirthDate, r.AsOfDate)
                    - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, dm.BirthDate, r.AsOfDate), dm.BirthDate) > r.AsOfDate
                           THEN 1 ELSE 0 END AS Years) age
WHERE c.StoreID IS NULL;      -- individuals only; stores are loaded into DimReseller

PRINT 'DimCustomer transformation completed.';
GO

PRINT 'VERIFYING DimCustomer...';
SELECT * FROM #DimCustomer_Transform WHERE CustomerAlternateKey IS NULL;
SELECT CustomerAlternateKey, COUNT(*) AS RecordCount FROM #DimCustomer_Transform WHERE rn = 1
GROUP BY CustomerAlternateKey HAVING COUNT(*) > 1;
SELECT SUM(CASE WHEN City = N'Unknown' THEN 1 ELSE 0 END) AS UnknownGeography,
       SUM(CASE WHEN Gender = N'Unknown' THEN 1 ELSE 0 END) AS UnknownDemographics,
       COUNT(*) AS TotalCustomers
FROM #DimCustomer_Transform WHERE rn = 1;
SELECT AgeGroup, COUNT(*) AS Customers FROM #DimCustomer_Transform WHERE rn = 1 GROUP BY AgeGroup;
SELECT TOP 20 * FROM #DimCustomer_Transform WHERE rn = 1 ORDER BY CustomerAlternateKey;
GO

DECLARE @t DATETIME2(0) = SYSDATETIME(), @rc INT;
BEGIN TRY
    BEGIN TRANSACTION;
    MERGE edw.DimCustomer AS tgt
    USING (SELECT * FROM #DimCustomer_Transform WHERE rn = 1) AS src
       ON tgt.CustomerAlternateKey = src.CustomerAlternateKey
    WHEN MATCHED AND EXISTS (SELECT src.AccountNumber, src.Title, src.FirstName, src.MiddleName, src.LastName, src.FullName, src.BirthDate,
                                    src.AgeGroup, src.Gender, src.MaritalStatus, src.YearlyIncome, src.TotalChildren, src.NumberChildrenAtHome,
                                    src.Education, src.Occupation, src.HomeOwnerFlag, src.NumberCarsOwned, src.CommuteDistance,
                                    src.DateFirstPurchase, src.EmailPromotion, src.EmailPromotionDesc, src.City, src.StateProvinceName,
                                    src.PostalCode, src.CountryRegionCode, src.CountryRegionName
                             EXCEPT
                             SELECT tgt.AccountNumber, tgt.Title, tgt.FirstName, tgt.MiddleName, tgt.LastName, tgt.FullName, tgt.BirthDate,
                                    tgt.AgeGroup, tgt.Gender, tgt.MaritalStatus, tgt.YearlyIncome, tgt.TotalChildren, tgt.NumberChildrenAtHome,
                                    tgt.Education, tgt.Occupation, tgt.HomeOwnerFlag, tgt.NumberCarsOwned, tgt.CommuteDistance,
                                    tgt.DateFirstPurchase, tgt.EmailPromotion, tgt.EmailPromotionDesc, tgt.City, tgt.StateProvinceName,
                                    tgt.PostalCode, tgt.CountryRegionCode, tgt.CountryRegionName)
        THEN UPDATE SET AccountNumber = src.AccountNumber, Title = src.Title, FirstName = src.FirstName, MiddleName = src.MiddleName,
                        LastName = src.LastName, FullName = src.FullName, BirthDate = src.BirthDate, AgeGroup = src.AgeGroup,
                        Gender = src.Gender, MaritalStatus = src.MaritalStatus, YearlyIncome = src.YearlyIncome,
                        TotalChildren = src.TotalChildren, NumberChildrenAtHome = src.NumberChildrenAtHome, Education = src.Education,
                        Occupation = src.Occupation, HomeOwnerFlag = src.HomeOwnerFlag, NumberCarsOwned = src.NumberCarsOwned,
                        CommuteDistance = src.CommuteDistance, DateFirstPurchase = src.DateFirstPurchase,
                        EmailPromotion = src.EmailPromotion, EmailPromotionDesc = src.EmailPromotionDesc, City = src.City,
                        StateProvinceName = src.StateProvinceName, PostalCode = src.PostalCode,
                        CountryRegionCode = src.CountryRegionCode, CountryRegionName = src.CountryRegionName,
                        ETLUpdateDate = SYSDATETIME()
    WHEN NOT MATCHED BY TARGET
        THEN INSERT (CustomerAlternateKey, AccountNumber, Title, FirstName, MiddleName, LastName, FullName, BirthDate, AgeGroup,
                     Gender, MaritalStatus, YearlyIncome, TotalChildren, NumberChildrenAtHome, Education, Occupation, HomeOwnerFlag,
                     NumberCarsOwned, CommuteDistance, DateFirstPurchase, EmailPromotion, EmailPromotionDesc, City,
                     StateProvinceName, PostalCode, CountryRegionCode, CountryRegionName)
             VALUES (src.CustomerAlternateKey, src.AccountNumber, src.Title, src.FirstName, src.MiddleName, src.LastName, src.FullName,
                     src.BirthDate, src.AgeGroup, src.Gender, src.MaritalStatus, src.YearlyIncome, src.TotalChildren,
                     src.NumberChildrenAtHome, src.Education, src.Occupation, src.HomeOwnerFlag, src.NumberCarsOwned,
                     src.CommuteDistance, src.DateFirstPurchase, src.EmailPromotion, src.EmailPromotionDesc, src.City,
                     src.StateProvinceName, src.PostalCode, src.CountryRegionCode, src.CountryRegionName);
    SET @rc = @@ROWCOUNT;
    COMMIT TRANSACTION;
    EXEC etl.usp_LogStep N'Load Dimension', N'edw.DimCustomer', @rc, @t;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    DECLARE @err NVARCHAR(4000) = ERROR_MESSAGE();
    EXEC etl.usp_LogStep N'Load Dimension', N'edw.DimCustomer', 0, @t, N'Failed', @err;
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(N'%s', 16, 1, @msg);   -- show the error
    SET NOEXEC ON;                   -- stop the remaining steps so facts never load on a failed dimension
END CATCH;
GO


/*==============================================================================
    6. DIM RESELLER 
==============================================================================*/
PRINT 'STEP 6: Transforming DimReseller...';

WITH XMLNAMESPACES (N'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/StoreSurvey' AS ns),
Geo AS
(
    SELECT bea.BusinessEntityID, a.City, a.PostalCode,
           sp.Name AS StateProvinceName, sp.CountryRegionCode, cr.Name AS CountryRegionName,
           ROW_NUMBER() OVER (PARTITION BY bea.BusinessEntityID
                              ORDER BY CASE WHEN bea.AddressTypeID = 3 THEN 0 ELSE 1 END, a.AddressID DESC) AS rn   -- 3 = Main Office
    FROM stg.BusinessEntityAddress bea
    JOIN stg.Address a            ON a.AddressID = bea.AddressID
    LEFT JOIN stg.StateProvince sp ON sp.StateProvinceID = a.StateProvinceID
    LEFT JOIN stg.CountryRegion cr ON cr.CountryRegionCode = sp.CountryRegionCode
),
Survey AS
(
    SELECT s.BusinessEntityID,
           v.x.value('(ns:AnnualSales)[1]',     'decimal(19,4)') AS AnnualSales,
           v.x.value('(ns:AnnualRevenue)[1]',   'decimal(19,4)') AS AnnualRevenue,
           v.x.value('(ns:BankName)[1]',        'nvarchar(50)')  AS BankName,
           v.x.value('(ns:BusinessType)[1]',    'nvarchar(5)')   AS BusinessType,
           v.x.value('(ns:YearOpened)[1]',      'int')           AS YearOpened,
           v.x.value('(ns:Specialty)[1]',       'nvarchar(20)')  AS Specialty,
           v.x.value('(ns:SquareFeet)[1]',      'int')           AS SquareFeet,
           v.x.value('(ns:NumberEmployees)[1]', 'int')           AS NumberEmployees
    FROM stg.Store s
    CROSS APPLY (SELECT CAST(s.Demographics AS XML) AS Doc) d
    OUTER APPLY d.Doc.nodes('/ns:StoreSurvey') AS v(x)
)
SELECT
    s.BusinessEntityID                                                AS ResellerAlternateKey,
    ISNULL(etl.fn_CleanText(s.Name), N'Unknown Reseller')             AS ResellerName,
    CASE sv.BusinessType WHEN N'BM' THEN N'Value Added Reseller'
                         WHEN N'BS' THEN N'Specialty Bike Shop'
                         WHEN N'OS' THEN N'Warehouse'
                         ELSE N'Unknown' END                          AS BusinessType,
    ISNULL(etl.fn_CleanText(sv.Specialty), N'Unknown')                AS Specialty,
    CAST(sv.YearOpened AS SMALLINT)                                   AS YearOpened,
    sv.NumberEmployees, sv.SquareFeet, sv.AnnualSales, sv.AnnualRevenue,
    etl.fn_CleanText(sv.BankName)                                     AS BankName,
    ISNULL(etl.fn_CleanText(g.City), N'Unknown')                      AS City,
    ISNULL(etl.fn_CleanText(g.StateProvinceName), N'Unknown')         AS StateProvinceName,
    etl.fn_CleanText(g.PostalCode)                                    AS PostalCode,
    UPPER(ISNULL(etl.fn_CleanText(g.CountryRegionCode), N'UNK'))      AS CountryRegionCode,
    ISNULL(etl.fn_CleanText(g.CountryRegionName), N'Unknown')         AS CountryRegionName,
    ROW_NUMBER() OVER (PARTITION BY s.BusinessEntityID ORDER BY s.BusinessEntityID) AS rn
INTO #DimReseller_Transform
FROM stg.Store s
LEFT JOIN Survey sv ON sv.BusinessEntityID = s.BusinessEntityID
LEFT JOIN Geo g     ON g.BusinessEntityID = s.BusinessEntityID AND g.rn = 1;

PRINT 'DimReseller transformation completed.';
GO

PRINT 'VERIFYING DimReseller...';
SELECT ResellerAlternateKey, COUNT(*) AS RecordCount FROM #DimReseller_Transform WHERE rn = 1
GROUP BY ResellerAlternateKey HAVING COUNT(*) > 1;
SELECT BusinessType, COUNT(*) AS Resellers FROM #DimReseller_Transform WHERE rn = 1 GROUP BY BusinessType;
SELECT TOP 20 * FROM #DimReseller_Transform WHERE rn = 1 ORDER BY ResellerAlternateKey;
GO

DECLARE @t DATETIME2(0) = SYSDATETIME(), @rc INT;
BEGIN TRY
    BEGIN TRANSACTION;
    MERGE edw.DimReseller AS tgt
    USING (SELECT * FROM #DimReseller_Transform WHERE rn = 1) AS src
       ON tgt.ResellerAlternateKey = src.ResellerAlternateKey
    WHEN MATCHED AND EXISTS (SELECT src.ResellerName, src.BusinessType, src.Specialty, src.YearOpened, src.NumberEmployees, src.SquareFeet,
                                    src.AnnualSales, src.AnnualRevenue, src.BankName, src.City, src.StateProvinceName, src.PostalCode,
                                    src.CountryRegionCode, src.CountryRegionName
                             EXCEPT
                             SELECT tgt.ResellerName, tgt.BusinessType, tgt.Specialty, tgt.YearOpened, tgt.NumberEmployees, tgt.SquareFeet,
                                    tgt.AnnualSales, tgt.AnnualRevenue, tgt.BankName, tgt.City, tgt.StateProvinceName, tgt.PostalCode,
                                    tgt.CountryRegionCode, tgt.CountryRegionName)
        THEN UPDATE SET ResellerName = src.ResellerName, BusinessType = src.BusinessType, Specialty = src.Specialty,
                        YearOpened = src.YearOpened, NumberEmployees = src.NumberEmployees, SquareFeet = src.SquareFeet,
                        AnnualSales = src.AnnualSales, AnnualRevenue = src.AnnualRevenue, BankName = src.BankName, City = src.City,
                        StateProvinceName = src.StateProvinceName, PostalCode = src.PostalCode,
                        CountryRegionCode = src.CountryRegionCode, CountryRegionName = src.CountryRegionName,
                        ETLUpdateDate = SYSDATETIME()
    WHEN NOT MATCHED BY TARGET
        THEN INSERT (ResellerAlternateKey, ResellerName, BusinessType, Specialty, YearOpened, NumberEmployees, SquareFeet,
                     AnnualSales, AnnualRevenue, BankName, City, StateProvinceName, PostalCode, CountryRegionCode, CountryRegionName)
             VALUES (src.ResellerAlternateKey, src.ResellerName, src.BusinessType, src.Specialty, src.YearOpened, src.NumberEmployees,
                     src.SquareFeet, src.AnnualSales, src.AnnualRevenue, src.BankName, src.City, src.StateProvinceName,
                     src.PostalCode, src.CountryRegionCode, src.CountryRegionName);
    SET @rc = @@ROWCOUNT;
    COMMIT TRANSACTION;
    EXEC etl.usp_LogStep N'Load Dimension', N'edw.DimReseller', @rc, @t;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    DECLARE @err NVARCHAR(4000) = ERROR_MESSAGE();
    EXEC etl.usp_LogStep N'Load Dimension', N'edw.DimReseller', 0, @t, N'Failed', @err;
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(N'%s', 16, 1, @msg);   -- show the error
    SET NOEXEC ON;                   -- stop the remaining steps so facts never load on a failed dimension
END CATCH;
GO


/*==============================================================================
    7. DIM EMPLOYEE  
==============================================================================*/
PRINT 'STEP 7: Transforming DimEmployee...';

WITH CurrentDept AS
(
    SELECT edh.BusinessEntityID, d.Name AS DepartmentName, d.GroupName, sh.Name AS ShiftName,
           ROW_NUMBER() OVER (PARTITION BY edh.BusinessEntityID
                              ORDER BY CASE WHEN edh.EndDate IS NULL THEN 0 ELSE 1 END, edh.StartDate DESC) AS rn
    FROM stg.EmployeeDepartmentHistory edh
    LEFT JOIN stg.Department d ON d.DepartmentID = edh.DepartmentID
    LEFT JOIN stg.Shift sh     ON sh.ShiftID = edh.ShiftID
)
SELECT
    e.BusinessEntityID                                                AS EmployeeAlternateKey,
    e.OrganizationNode,
    e.ParentOrganizationNode,
    e.OrganizationLevel,
    ISNULL(etl.fn_CleanText(p.FirstName), N'Unknown')                 AS FirstName,
    ISNULL(etl.fn_CleanText(p.LastName), N'Unknown')                  AS LastName,
    ISNULL(NULLIF(CONCAT_WS(N' ', etl.fn_CleanText(p.FirstName), etl.fn_CleanText(p.LastName)), N''), N'Unknown') AS FullName,
    etl.fn_CleanText(e.LoginID)                                       AS LoginID,
    ISNULL(etl.fn_CleanText(e.JobTitle), N'Unknown')                  AS JobTitle,
    ISNULL(cd.DepartmentName, N'Unknown')                             AS DepartmentName,
    ISNULL(cd.GroupName, N'Unknown')                                  AS DepartmentGroupName,
    ISNULL(cd.ShiftName, N'Unknown')                                  AS ShiftName,
    CASE e.Gender WHEN N'M' THEN N'Male' WHEN N'F' THEN N'Female' ELSE N'Unknown' END          AS Gender,
    CASE e.MaritalStatus WHEN N'M' THEN N'Married' WHEN N'S' THEN N'Single' ELSE N'Unknown' END AS MaritalStatus,
    e.BirthDate, e.HireDate, e.SalariedFlag, e.VacationHours, e.SickLeaveHours, e.CurrentFlag,
    CAST(CASE WHEN sp.BusinessEntityID IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS IsSalesPerson,
    sp.TerritoryID                                                    AS SalesTerritoryAlternateKey,
    ROW_NUMBER() OVER (PARTITION BY e.BusinessEntityID ORDER BY e.BusinessEntityID) AS rn
INTO #DimEmployee_Transform
FROM stg.Employee e
LEFT JOIN stg.Person p       ON p.BusinessEntityID = e.BusinessEntityID
LEFT JOIN CurrentDept cd     ON cd.BusinessEntityID = e.BusinessEntityID AND cd.rn = 1
LEFT JOIN stg.SalesPerson sp ON sp.BusinessEntityID = e.BusinessEntityID;

PRINT 'DimEmployee transformation completed.';
GO

PRINT 'VERIFYING DimEmployee...';
SELECT EmployeeAlternateKey, COUNT(*) AS RecordCount FROM #DimEmployee_Transform WHERE rn = 1
GROUP BY EmployeeAlternateKey HAVING COUNT(*) > 1;
SELECT SUM(CASE WHEN ParentOrganizationNode IS NULL THEN 1 ELSE 0 END) AS TopLevelEmployees,      -- expected: 1 (CEO)
       SUM(CAST(IsSalesPerson AS INT)) AS SalesPeople, COUNT(*) AS TotalEmployees
FROM #DimEmployee_Transform WHERE rn = 1;
SELECT TOP 20 * FROM #DimEmployee_Transform WHERE rn = 1 ORDER BY OrganizationLevel, EmployeeAlternateKey;
GO

DECLARE @t DATETIME2(0) = SYSDATETIME(), @rc INT;
BEGIN TRY
    BEGIN TRANSACTION;
    MERGE edw.DimEmployee AS tgt
    USING (SELECT t.*, ISNULL(dt.TerritoryKey, -1) AS SalesTerritoryKey
           FROM #DimEmployee_Transform t
           LEFT JOIN edw.DimTerritory dt ON dt.TerritoryAlternateKey = t.SalesTerritoryAlternateKey
           WHERE t.rn = 1) AS src
       ON tgt.EmployeeAlternateKey = src.EmployeeAlternateKey
    WHEN MATCHED AND EXISTS (SELECT src.OrganizationNode, src.OrganizationLevel, src.FirstName, src.LastName, src.FullName, src.LoginID,
                                    src.JobTitle, src.DepartmentName, src.DepartmentGroupName, src.ShiftName, src.Gender, src.MaritalStatus,
                                    src.BirthDate, src.HireDate, src.SalariedFlag, src.VacationHours, src.SickLeaveHours, src.CurrentFlag,
                                    src.IsSalesPerson, src.SalesTerritoryKey
                             EXCEPT
                             SELECT tgt.OrganizationNode, tgt.OrganizationLevel, tgt.FirstName, tgt.LastName, tgt.FullName, tgt.LoginID,
                                    tgt.JobTitle, tgt.DepartmentName, tgt.DepartmentGroupName, tgt.ShiftName, tgt.Gender, tgt.MaritalStatus,
                                    tgt.BirthDate, tgt.HireDate, tgt.SalariedFlag, tgt.VacationHours, tgt.SickLeaveHours, tgt.CurrentFlag,
                                    tgt.IsSalesPerson, tgt.SalesTerritoryKey)
        THEN UPDATE SET OrganizationNode = src.OrganizationNode, OrganizationLevel = src.OrganizationLevel, FirstName = src.FirstName,
                        LastName = src.LastName, FullName = src.FullName, LoginID = src.LoginID, JobTitle = src.JobTitle,
                        DepartmentName = src.DepartmentName, DepartmentGroupName = src.DepartmentGroupName, ShiftName = src.ShiftName,
                        Gender = src.Gender, MaritalStatus = src.MaritalStatus, BirthDate = src.BirthDate, HireDate = src.HireDate,
                        SalariedFlag = src.SalariedFlag, VacationHours = src.VacationHours, SickLeaveHours = src.SickLeaveHours,
                        CurrentFlag = src.CurrentFlag, IsSalesPerson = src.IsSalesPerson, SalesTerritoryKey = src.SalesTerritoryKey,
                        ETLUpdateDate = SYSDATETIME()
    WHEN NOT MATCHED BY TARGET
        THEN INSERT (EmployeeAlternateKey, OrganizationNode, OrganizationLevel, FirstName, LastName, FullName, LoginID, JobTitle,
                     DepartmentName, DepartmentGroupName, ShiftName, Gender, MaritalStatus, BirthDate, HireDate, SalariedFlag,
                     VacationHours, SickLeaveHours, CurrentFlag, IsSalesPerson, SalesTerritoryKey)
             VALUES (src.EmployeeAlternateKey, src.OrganizationNode, src.OrganizationLevel, src.FirstName, src.LastName, src.FullName,
                     src.LoginID, src.JobTitle, src.DepartmentName, src.DepartmentGroupName, src.ShiftName, src.Gender,
                     src.MaritalStatus, src.BirthDate, src.HireDate, src.SalariedFlag, src.VacationHours, src.SickLeaveHours,
                     src.CurrentFlag, src.IsSalesPerson, src.SalesTerritoryKey);
    SET @rc = @@ROWCOUNT;

    -- Resolve the parent-child hierarchy (manager) now that every employee has a surrogate key
    UPDATE child
    SET    child.ParentEmployeeKey = parent.EmployeeKey
    FROM   edw.DimEmployee child
    JOIN   #DimEmployee_Transform t ON t.EmployeeAlternateKey = child.EmployeeAlternateKey AND t.rn = 1
    JOIN   edw.DimEmployee parent   ON parent.OrganizationNode = t.ParentOrganizationNode
    WHERE  ISNULL(child.ParentEmployeeKey, -999) <> parent.EmployeeKey;

    COMMIT TRANSACTION;
    EXEC etl.usp_LogStep N'Load Dimension', N'edw.DimEmployee', @rc, @t;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    DECLARE @err NVARCHAR(4000) = ERROR_MESSAGE();
    EXEC etl.usp_LogStep N'Load Dimension', N'edw.DimEmployee', 0, @t, N'Failed', @err;
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(N'%s', 16, 1, @msg);   -- show the error
    SET NOEXEC ON;                   -- stop the remaining steps so facts never load on a failed dimension
END CATCH;
GO


/*==============================================================================
    8. DIM VENDOR  
==============================================================================*/
PRINT 'STEP 8: Transforming DimVendor...';

WITH Geo AS
(
    SELECT bea.BusinessEntityID, a.City, sp.Name AS StateProvinceName, sp.CountryRegionCode,
           ROW_NUMBER() OVER (PARTITION BY bea.BusinessEntityID
                              ORDER BY CASE WHEN bea.AddressTypeID = 3 THEN 0 ELSE 1 END, a.AddressID DESC) AS rn
    FROM stg.BusinessEntityAddress bea
    JOIN stg.Address a            ON a.AddressID = bea.AddressID
    LEFT JOIN stg.StateProvince sp ON sp.StateProvinceID = a.StateProvinceID
)
SELECT
    v.BusinessEntityID                                         AS VendorAlternateKey,
    etl.fn_CleanText(v.AccountNumber)                          AS AccountNumber,
    ISNULL(etl.fn_CleanText(v.Name), N'Unknown Vendor')        AS VendorName,
    v.CreditRating,
    CASE v.CreditRating WHEN 1 THEN N'Superior' WHEN 2 THEN N'Excellent' WHEN 3 THEN N'Above Average'
                        WHEN 4 THEN N'Average'  WHEN 5 THEN N'Below Average' ELSE N'Unknown' END AS CreditRatingDesc,
    v.PreferredVendorStatus                                    AS PreferredVendorFlag,
    v.ActiveFlag,
    ISNULL(etl.fn_CleanText(g.City), N'Unknown')               AS City,
    ISNULL(etl.fn_CleanText(g.StateProvinceName), N'Unknown')  AS StateProvinceName,
    UPPER(ISNULL(etl.fn_CleanText(g.CountryRegionCode), N'UNK')) AS CountryRegionCode,
    ROW_NUMBER() OVER (PARTITION BY v.BusinessEntityID ORDER BY v.BusinessEntityID) AS rn
INTO #DimVendor_Transform
FROM stg.Vendor v
LEFT JOIN Geo g ON g.BusinessEntityID = v.BusinessEntityID AND g.rn = 1;

PRINT 'DimVendor transformation completed.';
GO

PRINT 'VERIFYING DimVendor...';
SELECT VendorAlternateKey, COUNT(*) AS RecordCount FROM #DimVendor_Transform WHERE rn = 1
GROUP BY VendorAlternateKey HAVING COUNT(*) > 1;
SELECT CreditRatingDesc, COUNT(*) AS Vendors FROM #DimVendor_Transform WHERE rn = 1 GROUP BY CreditRatingDesc;
GO

DECLARE @t DATETIME2(0) = SYSDATETIME(), @rc INT;
BEGIN TRY
    BEGIN TRANSACTION;
    MERGE edw.DimVendor AS tgt
    USING (SELECT * FROM #DimVendor_Transform WHERE rn = 1) AS src
       ON tgt.VendorAlternateKey = src.VendorAlternateKey
    WHEN MATCHED AND EXISTS (SELECT src.AccountNumber, src.VendorName, src.CreditRating, src.CreditRatingDesc, src.PreferredVendorFlag,
                                    src.ActiveFlag, src.City, src.StateProvinceName, src.CountryRegionCode
                             EXCEPT
                             SELECT tgt.AccountNumber, tgt.VendorName, tgt.CreditRating, tgt.CreditRatingDesc, tgt.PreferredVendorFlag,
                                    tgt.ActiveFlag, tgt.City, tgt.StateProvinceName, tgt.CountryRegionCode)
        THEN UPDATE SET AccountNumber = src.AccountNumber, VendorName = src.VendorName, CreditRating = src.CreditRating,
                        CreditRatingDesc = src.CreditRatingDesc, PreferredVendorFlag = src.PreferredVendorFlag,
                        ActiveFlag = src.ActiveFlag, City = src.City, StateProvinceName = src.StateProvinceName,
                        CountryRegionCode = src.CountryRegionCode
    WHEN NOT MATCHED BY TARGET
        THEN INSERT (VendorAlternateKey, AccountNumber, VendorName, CreditRating, CreditRatingDesc, PreferredVendorFlag,
                     ActiveFlag, City, StateProvinceName, CountryRegionCode)
             VALUES (src.VendorAlternateKey, src.AccountNumber, src.VendorName, src.CreditRating, src.CreditRatingDesc,
                     src.PreferredVendorFlag, src.ActiveFlag, src.City, src.StateProvinceName, src.CountryRegionCode);
    SET @rc = @@ROWCOUNT;
    COMMIT TRANSACTION;
    EXEC etl.usp_LogStep N'Load Dimension', N'edw.DimVendor', @rc, @t;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    DECLARE @err NVARCHAR(4000) = ERROR_MESSAGE();
    EXEC etl.usp_LogStep N'Load Dimension', N'edw.DimVendor', 0, @t, N'Failed', @err;
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(N'%s', 16, 1, @msg);   -- show the error
    SET NOEXEC ON;                   -- stop the remaining steps so facts never load on a failed dimension
END CATCH;
GO


/*==============================================================================
    9. POST-LOAD VERIFY DIMENSIONS
==============================================================================*/
PRINT 'POST-LOAD DIMENSION VERIFICATION';

SELECT 'DimDate' AS DimensionName, COUNT(*) AS RowCnt FROM edw.DimDate
UNION ALL SELECT 'DimProduct',     COUNT(*) FROM edw.DimProduct
UNION ALL SELECT 'DimCustomer',    COUNT(*) FROM edw.DimCustomer
UNION ALL SELECT 'DimReseller',    COUNT(*) FROM edw.DimReseller
UNION ALL SELECT 'DimEmployee',    COUNT(*) FROM edw.DimEmployee
UNION ALL SELECT 'DimTerritory',   COUNT(*) FROM edw.DimTerritory
UNION ALL SELECT 'DimPromotion',   COUNT(*) FROM edw.DimPromotion
UNION ALL SELECT 'DimSalesReason', COUNT(*) FROM edw.DimSalesReason
UNION ALL SELECT 'DimVendor',      COUNT(*) FROM edw.DimVendor
UNION ALL SELECT 'DimShipMethod',  COUNT(*) FROM edw.DimShipMethod
UNION ALL SELECT 'DimLocation',    COUNT(*) FROM edw.DimLocation
UNION ALL SELECT 'DimScrapReason', COUNT(*) FROM edw.DimScrapReason
UNION ALL SELECT 'DimCurrency',    COUNT(*) FROM edw.DimCurrency;
GO


/*==============================================================================
    10. FACT SALES 
==============================================================================*/
PRINT 'STEP 10: Transforming FactSales...';

SELECT
    soh.SalesOrderNumber,
    CAST(ROW_NUMBER() OVER (PARTITION BY soh.SalesOrderID ORDER BY sod.SalesOrderDetailID) AS SMALLINT) AS SalesOrderLineNumber,
    CASE WHEN soh.OnlineOrderFlag = 1 THEN N'Internet' ELSE N'Reseller' END                  AS SalesChannel,
    soh.OnlineOrderFlag,

    /* Role-playing date keys */
    ISNULL(CONVERT(INT, CONVERT(CHAR(8), soh.OrderDate, 112)), -1)                         AS OrderDateKey,
    ISNULL(CONVERT(INT, CONVERT(CHAR(8), soh.DueDate,   112)), -1)                         AS DueDateKey,
    ISNULL(CONVERT(INT, CONVERT(CHAR(8), soh.ShipDate,  112)), -1)                         AS ShipDateKey,

    /* Surrogate key lookups (Unknown member when no match) */
    ISNULL(dp.ProductKey, -1)     AS ProductKey,
    ISNULL(dc.CustomerKey, -1)    AS CustomerKey,
    ISNULL(dr.ResellerKey, -1)    AS ResellerKey,
    ISNULL(de.EmployeeKey, -1)    AS EmployeeKey,
    ISNULL(dt.TerritoryKey, -1)   AS TerritoryKey,
    ISNULL(dpr.PromotionKey, -1)  AS PromotionKey,
    ISNULL(dsm.ShipMethodKey, -1) AS ShipMethodKey,
    ISNULL(dcu.CurrencyKey, -1)   AS CurrencyKey,

    /* Measures */
    CAST(sod.OrderQty AS INT)                                                              AS OrderQuantity,
    sod.UnitPrice,
    CAST(sod.OrderQty * sod.UnitPrice AS DECIMAL(19,4))                                    AS ExtendedAmount,
    CAST(sod.UnitPriceDiscount AS DECIMAL(10,4))                                           AS UnitPriceDiscountPct,
    CAST(sod.OrderQty * sod.UnitPrice * sod.UnitPriceDiscount AS DECIMAL(19,4))            AS DiscountAmount,
    CAST((sod.OrderQty * sod.UnitPrice) - (sod.OrderQty * sod.UnitPrice * sod.UnitPriceDiscount) AS DECIMAL(19,4)) AS SalesAmount,
    CAST(ISNULL(pch.StandardCost, ISNULL(dp.StandardCost, 0)) AS DECIMAL(19,4))            AS ProductStandardCost,
    CAST(sod.OrderQty * ISNULL(pch.StandardCost, ISNULL(dp.StandardCost, 0)) AS DECIMAL(19,4)) AS TotalProductCost,
    CAST(ISNULL(soh.TaxAmt  * sod.LineTotal / NULLIF(SUM(sod.LineTotal) OVER (PARTITION BY soh.SalesOrderID), 0), 0) AS DECIMAL(19,4)) AS TaxAmount,
    CAST(ISNULL(soh.Freight * sod.LineTotal / NULLIF(SUM(sod.LineTotal) OVER (PARTITION BY soh.SalesOrderID), 0), 0) AS DECIMAL(19,4)) AS FreightAmount,

    /* Duplicate detection on the grain */
    ROW_NUMBER() OVER (PARTITION BY soh.SalesOrderID, sod.SalesOrderDetailID ORDER BY soh.OrderDate DESC) AS rn
INTO #FactSales_Transform
FROM stg.SalesOrderHeader soh
JOIN stg.SalesOrderDetail sod       ON sod.SalesOrderID = soh.SalesOrderID
LEFT JOIN stg.Customer c            ON c.CustomerID = soh.CustomerID
LEFT JOIN stg.CurrencyRate cr       ON cr.CurrencyRateID = soh.CurrencyRateID
LEFT JOIN edw.DimProduct dp         ON dp.ProductAlternateKey = sod.ProductID
LEFT JOIN edw.DimCustomer dc        ON dc.CustomerAlternateKey = soh.CustomerID
LEFT JOIN edw.DimReseller dr        ON dr.ResellerAlternateKey = c.StoreID
LEFT JOIN edw.DimEmployee de        ON de.EmployeeAlternateKey = soh.SalesPersonID
LEFT JOIN edw.DimTerritory dt       ON dt.TerritoryAlternateKey = soh.TerritoryID
LEFT JOIN edw.DimPromotion dpr      ON dpr.PromotionAlternateKey = sod.SpecialOfferID
LEFT JOIN edw.DimShipMethod dsm     ON dsm.ShipMethodAlternateKey = soh.ShipMethodID
LEFT JOIN edw.DimCurrency dcu       ON dcu.CurrencyAlternateKey = ISNULL(cr.ToCurrencyCode, N'USD')   -- no rate = USD order
OUTER APPLY
(
    SELECT TOP (1) h.StandardCost            -- unit cost that was valid on the order date
    FROM stg.ProductCostHistory h
    WHERE h.ProductID = sod.ProductID
      AND h.StartDate <= soh.OrderDate
    ORDER BY h.StartDate DESC
) pch;

PRINT 'FactSales transformation completed.';
GO

PRINT 'VERIFYING FactSales...';
-- A. NULL / invalid measures (must return 0 rows)
SELECT COUNT(*) AS InvalidRows FROM #FactSales_Transform
WHERE SalesOrderNumber IS NULL OR OrderQuantity <= 0 OR UnitPrice IS NULL OR SalesAmount < 0 OR DiscountAmount < 0;
-- B. Rows mapped to Unknown members (expected: CustomerKey -1 = reseller lines, ResellerKey -1 = internet lines)
SELECT SalesChannel,
       SUM(CASE WHEN ProductKey  = -1 THEN 1 ELSE 0 END) AS UnknownProduct,
       SUM(CASE WHEN CustomerKey = -1 THEN 1 ELSE 0 END) AS UnknownCustomer,
       SUM(CASE WHEN ResellerKey = -1 THEN 1 ELSE 0 END) AS UnknownReseller,
       SUM(CASE WHEN EmployeeKey = -1 THEN 1 ELSE 0 END) AS NoSalesPerson,
       SUM(CASE WHEN TerritoryKey = -1 THEN 1 ELSE 0 END) AS UnknownTerritory,
       SUM(CASE WHEN PromotionKey = -1 THEN 1 ELSE 0 END) AS UnknownPromotion,
       COUNT(*) AS TotalLines
FROM #FactSales_Transform WHERE rn = 1 GROUP BY SalesChannel;
-- C. Duplicate grain (must return 0 rows)
SELECT SalesOrderNumber, SalesOrderLineNumber, COUNT(*) AS RecordCount
FROM #FactSales_Transform WHERE rn = 1
GROUP BY SalesOrderNumber, SalesOrderLineNumber HAVING COUNT(*) > 1;
-- D. Allocated tax and freight reconcile to the order headers
SELECT CAST(SUM(f.TaxAmount) AS DECIMAL(19,2)) AS AllocatedTax, (SELECT CAST(SUM(TaxAmt) AS DECIMAL(19,2)) FROM stg.SalesOrderHeader) AS HeaderTax,
       CAST(SUM(f.FreightAmount) AS DECIMAL(19,2)) AS AllocatedFreight, (SELECT CAST(SUM(Freight) AS DECIMAL(19,2)) FROM stg.SalesOrderHeader) AS HeaderFreight
FROM #FactSales_Transform f WHERE rn = 1;
-- E. Summary by channel
SELECT SalesChannel, COUNT(*) AS Lines, COUNT(DISTINCT SalesOrderNumber) AS Orders, SUM(OrderQuantity) AS Quantity,
       SUM(SalesAmount) AS SalesAmount, SUM(TotalProductCost) AS TotalProductCost, SUM(DiscountAmount) AS Discount
FROM #FactSales_Transform WHERE rn = 1 GROUP BY SalesChannel;
GO

DECLARE @t DATETIME2(0) = SYSDATETIME(), @rc INT;
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO edw.FactSales
    (
        SalesOrderNumber, SalesOrderLineNumber, SalesChannel, OnlineOrderFlag, OrderDateKey, DueDateKey, ShipDateKey,
        ProductKey, CustomerKey, ResellerKey, EmployeeKey, TerritoryKey, PromotionKey, ShipMethodKey, CurrencyKey,
        OrderQuantity, UnitPrice, ExtendedAmount, UnitPriceDiscountPct, DiscountAmount, SalesAmount,
        ProductStandardCost, TotalProductCost, GrossProfit, TaxAmount, FreightAmount
    )
    SELECT
        f.SalesOrderNumber, f.SalesOrderLineNumber, f.SalesChannel, f.OnlineOrderFlag, f.OrderDateKey, f.DueDateKey, f.ShipDateKey,
        f.ProductKey, f.CustomerKey, f.ResellerKey, f.EmployeeKey, f.TerritoryKey, f.PromotionKey, f.ShipMethodKey, f.CurrencyKey,
        f.OrderQuantity, f.UnitPrice, f.ExtendedAmount, f.UnitPriceDiscountPct, f.DiscountAmount, f.SalesAmount,
        f.ProductStandardCost, f.TotalProductCost, f.SalesAmount - f.TotalProductCost, f.TaxAmount, f.FreightAmount
    FROM #FactSales_Transform f
    WHERE f.rn = 1
      AND NOT EXISTS (SELECT 1 FROM edw.FactSales fs
                      WHERE fs.SalesOrderNumber = f.SalesOrderNumber AND fs.SalesOrderLineNumber = f.SalesOrderLineNumber);
    SET @rc = @@ROWCOUNT;
    COMMIT TRANSACTION;
    EXEC etl.usp_LogStep N'Load Fact', N'edw.FactSales', @rc, @t;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    DECLARE @err NVARCHAR(4000) = ERROR_MESSAGE();
    EXEC etl.usp_LogStep N'Load Fact', N'edw.FactSales', 0, @t, N'Failed', @err;
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(N'%s', 16, 1, @msg);   -- show the error
    SET NOEXEC ON;                   -- stop the remaining steps so facts never load on a failed dimension
END CATCH;
GO


/*==============================================================================
    11. FACT SALES REASON  (factless)
==============================================================================*/
PRINT 'STEP 11: Transforming FactSalesReason...';

SELECT
    soh.SalesOrderNumber,
    ISNULL(dsr.SalesReasonKey, -1)                                  AS SalesReasonKey,
    ISNULL(CONVERT(INT, CONVERT(CHAR(8), soh.OrderDate, 112)), -1)  AS OrderDateKey,
    ISNULL(dc.CustomerKey, -1)                                      AS CustomerKey,
    ISNULL(dt.TerritoryKey, -1)                                     AS TerritoryKey,
    ROW_NUMBER() OVER (PARTITION BY r.SalesOrderID, r.SalesReasonID ORDER BY r.SalesOrderID) AS rn
INTO #FactSalesReason_Transform
FROM stg.SalesOrderHeaderSalesReason r
JOIN stg.SalesOrderHeader soh   ON soh.SalesOrderID = r.SalesOrderID
LEFT JOIN edw.DimSalesReason dsr ON dsr.SalesReasonAlternateKey = r.SalesReasonID
LEFT JOIN edw.DimCustomer dc     ON dc.CustomerAlternateKey = soh.CustomerID
LEFT JOIN edw.DimTerritory dt    ON dt.TerritoryAlternateKey = soh.TerritoryID;
GO

SELECT COUNT(*) AS ReasonRows, SUM(CASE WHEN SalesReasonKey = -1 THEN 1 ELSE 0 END) AS UnknownReason
FROM #FactSalesReason_Transform WHERE rn = 1;
GO

DECLARE @t DATETIME2(0) = SYSDATETIME(), @rc INT;
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO edw.FactSalesReason (SalesOrderNumber, SalesReasonKey, OrderDateKey, CustomerKey, TerritoryKey)
    SELECT f.SalesOrderNumber, f.SalesReasonKey, f.OrderDateKey, f.CustomerKey, f.TerritoryKey
    FROM #FactSalesReason_Transform f
    WHERE f.rn = 1
      AND NOT EXISTS (SELECT 1 FROM edw.FactSalesReason x
                      WHERE x.SalesOrderNumber = f.SalesOrderNumber AND x.SalesReasonKey = f.SalesReasonKey);
    SET @rc = @@ROWCOUNT;
    COMMIT TRANSACTION;
    EXEC etl.usp_LogStep N'Load Fact', N'edw.FactSalesReason', @rc, @t;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    DECLARE @err NVARCHAR(4000) = ERROR_MESSAGE();
    EXEC etl.usp_LogStep N'Load Fact', N'edw.FactSalesReason', 0, @t, N'Failed', @err;
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(N'%s', 16, 1, @msg);   -- show the error
    SET NOEXEC ON;                   -- stop the remaining steps so facts never load on a failed dimension
END CATCH;
GO


/*==============================================================================
    12. FACT SALES QUOTA
==============================================================================*/
PRINT 'STEP 12: Transforming FactSalesQuota...';

SELECT
    ISNULL(de.EmployeeKey, -1)                                      AS EmployeeKey,
    ISNULL(CONVERT(INT, CONVERT(CHAR(8), q.QuotaDate, 112)), -1)    AS QuotaDateKey,
    ISNULL(q.SalesQuota, 0)                                         AS SalesAmountQuota,
    ROW_NUMBER() OVER (PARTITION BY q.BusinessEntityID, q.QuotaDate ORDER BY q.QuotaDate) AS rn
INTO #FactSalesQuota_Transform
FROM stg.SalesPersonQuotaHistory q
LEFT JOIN edw.DimEmployee de ON de.EmployeeAlternateKey = q.BusinessEntityID;
GO

SELECT COUNT(*) AS QuotaRows, SUM(SalesAmountQuota) AS TotalQuota,
       SUM(CASE WHEN EmployeeKey = -1 THEN 1 ELSE 0 END) AS UnknownEmployee
FROM #FactSalesQuota_Transform WHERE rn = 1;
GO

DECLARE @t DATETIME2(0) = SYSDATETIME(), @rc INT;
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO edw.FactSalesQuota (EmployeeKey, QuotaDateKey, SalesAmountQuota)
    SELECT f.EmployeeKey, f.QuotaDateKey, f.SalesAmountQuota
    FROM #FactSalesQuota_Transform f
    WHERE f.rn = 1
      AND NOT EXISTS (SELECT 1 FROM edw.FactSalesQuota x WHERE x.EmployeeKey = f.EmployeeKey AND x.QuotaDateKey = f.QuotaDateKey);
    SET @rc = @@ROWCOUNT;
    COMMIT TRANSACTION;
    EXEC etl.usp_LogStep N'Load Fact', N'edw.FactSalesQuota', @rc, @t;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    DECLARE @err NVARCHAR(4000) = ERROR_MESSAGE();
    EXEC etl.usp_LogStep N'Load Fact', N'edw.FactSalesQuota', 0, @t, N'Failed', @err;
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(N'%s', 16, 1, @msg);   -- show the error
    SET NOEXEC ON;                   -- stop the remaining steps so facts never load on a failed dimension
END CATCH;
GO


/*==============================================================================
    13. FACT PURCHASES
==============================================================================*/
PRINT 'STEP 13: Transforming FactPurchases...';

SELECT
    CONCAT(N'PO', poh.PurchaseOrderID)                                                    AS PurchaseOrderNumber,
    CAST(ROW_NUMBER() OVER (PARTITION BY poh.PurchaseOrderID ORDER BY pod.PurchaseOrderDetailID) AS SMALLINT) AS PurchaseOrderLineNumber,
    CASE poh.Status WHEN 1 THEN N'Pending' WHEN 2 THEN N'Approved' WHEN 3 THEN N'Rejected' WHEN 4 THEN N'Complete'
                    ELSE N'Unknown' END                                                   AS OrderStatus,
    ISNULL(CONVERT(INT, CONVERT(CHAR(8), poh.OrderDate, 112)), -1)                        AS OrderDateKey,
    ISNULL(CONVERT(INT, CONVERT(CHAR(8), pod.DueDate,   112)), -1)                        AS DueDateKey,
    ISNULL(CONVERT(INT, CONVERT(CHAR(8), poh.ShipDate,  112)), -1)                        AS ShipDateKey,
    ISNULL(dp.ProductKey, -1)     AS ProductKey,
    ISNULL(dv.VendorKey, -1)      AS VendorKey,
    ISNULL(de.EmployeeKey, -1)    AS EmployeeKey,
    ISNULL(dsm.ShipMethodKey, -1) AS ShipMethodKey,
    CAST(pod.OrderQty AS INT)     AS OrderQuantity,
    pod.UnitPrice,
    pod.LineTotal,
    ISNULL(pod.ReceivedQty, 0)    AS ReceivedQuantity,
    ISNULL(pod.RejectedQty, 0)    AS RejectedQuantity,
    ISNULL(pod.StockedQty, 0)     AS StockedQuantity,
    CAST(ISNULL(poh.TaxAmt  * pod.LineTotal / NULLIF(SUM(pod.LineTotal) OVER (PARTITION BY poh.PurchaseOrderID), 0), 0) AS DECIMAL(19,4)) AS TaxAmount,
    CAST(ISNULL(poh.Freight * pod.LineTotal / NULLIF(SUM(pod.LineTotal) OVER (PARTITION BY poh.PurchaseOrderID), 0), 0) AS DECIMAL(19,4)) AS FreightAmount,
    ROW_NUMBER() OVER (PARTITION BY poh.PurchaseOrderID, pod.PurchaseOrderDetailID ORDER BY poh.OrderDate DESC) AS rn
INTO #FactPurchases_Transform
FROM stg.PurchaseOrderHeader poh
JOIN stg.PurchaseOrderDetail pod   ON pod.PurchaseOrderID = poh.PurchaseOrderID
LEFT JOIN edw.DimProduct dp        ON dp.ProductAlternateKey = pod.ProductID
LEFT JOIN edw.DimVendor dv         ON dv.VendorAlternateKey = poh.VendorID
LEFT JOIN edw.DimEmployee de       ON de.EmployeeAlternateKey = poh.EmployeeID
LEFT JOIN edw.DimShipMethod dsm    ON dsm.ShipMethodAlternateKey = poh.ShipMethodID;
GO

PRINT 'VERIFYING FactPurchases...';
SELECT COUNT(*) AS InvalidRows FROM #FactPurchases_Transform WHERE OrderQuantity <= 0 OR LineTotal < 0 OR RejectedQuantity > ReceivedQuantity;
SELECT PurchaseOrderNumber, PurchaseOrderLineNumber, COUNT(*) AS RecordCount FROM #FactPurchases_Transform WHERE rn = 1
GROUP BY PurchaseOrderNumber, PurchaseOrderLineNumber HAVING COUNT(*) > 1;
SELECT OrderStatus, COUNT(*) AS Lines, SUM(LineTotal) AS LineTotal, SUM(RejectedQuantity) AS Rejected
FROM #FactPurchases_Transform WHERE rn = 1 GROUP BY OrderStatus;
GO

DECLARE @t DATETIME2(0) = SYSDATETIME(), @rc INT;
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO edw.FactPurchases
    (
        PurchaseOrderNumber, PurchaseOrderLineNumber, OrderStatus, OrderDateKey, DueDateKey, ShipDateKey, ProductKey, VendorKey,
        EmployeeKey, ShipMethodKey, OrderQuantity, UnitPrice, LineTotal, ReceivedQuantity, RejectedQuantity, StockedQuantity,
        TaxAmount, FreightAmount
    )
    SELECT f.PurchaseOrderNumber, f.PurchaseOrderLineNumber, f.OrderStatus, f.OrderDateKey, f.DueDateKey, f.ShipDateKey, f.ProductKey,
           f.VendorKey, f.EmployeeKey, f.ShipMethodKey, f.OrderQuantity, f.UnitPrice, f.LineTotal, f.ReceivedQuantity,
           f.RejectedQuantity, f.StockedQuantity, f.TaxAmount, f.FreightAmount
    FROM #FactPurchases_Transform f
    WHERE f.rn = 1
      AND NOT EXISTS (SELECT 1 FROM edw.FactPurchases x
                      WHERE x.PurchaseOrderNumber = f.PurchaseOrderNumber AND x.PurchaseOrderLineNumber = f.PurchaseOrderLineNumber);
    SET @rc = @@ROWCOUNT;
    COMMIT TRANSACTION;
    EXEC etl.usp_LogStep N'Load Fact', N'edw.FactPurchases', @rc, @t;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    DECLARE @err NVARCHAR(4000) = ERROR_MESSAGE();
    EXEC etl.usp_LogStep N'Load Fact', N'edw.FactPurchases', 0, @t, N'Failed', @err;
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(N'%s', 16, 1, @msg);   -- show the error
    SET NOEXEC ON;                   -- stop the remaining steps so facts never load on a failed dimension
END CATCH;
GO


/*==============================================================================
    14. FACT PRODUCTION WORK ORDER  (work order + routing costs/hours)
==============================================================================*/
PRINT 'STEP 14: Transforming FactProductionWorkOrder...';

WITH Routing AS
(
    SELECT WorkOrderID,
           COUNT(*)               AS OperationCount,
           SUM(PlannedCost)       AS PlannedCost,
           SUM(ActualCost)        AS ActualCost,
           SUM(ActualResourceHrs) AS ActualResourceHours
    FROM stg.WorkOrderRouting
    GROUP BY WorkOrderID
)
SELECT
    wo.WorkOrderID                                                   AS WorkOrderNumber,
    ISNULL(dp.ProductKey, -1)                                        AS ProductKey,
    ISNULL(CONVERT(INT, CONVERT(CHAR(8), wo.StartDate, 112)), -1)    AS StartDateKey,
    ISNULL(CONVERT(INT, CONVERT(CHAR(8), wo.EndDate,   112)), -1)    AS EndDateKey,
    ISNULL(CONVERT(INT, CONVERT(CHAR(8), wo.DueDate,   112)), -1)    AS DueDateKey,
    ISNULL(dsr.ScrapReasonKey, -1)                                   AS ScrapReasonKey,
    wo.OrderQty                                                      AS OrderQuantity,
    wo.StockedQty                                                    AS StockedQuantity,
    CAST(wo.ScrappedQty AS INT)                                      AS ScrappedQuantity,
    DATEDIFF(DAY, wo.StartDate, wo.EndDate)                          AS ProductionDays,
    CASE WHEN wo.EndDate > wo.DueDate THEN DATEDIFF(DAY, wo.DueDate, wo.EndDate) ELSE 0 END AS DaysLate,
    ISNULL(r.OperationCount, 0)                                      AS OperationCount,
    CAST(ISNULL(r.PlannedCost, 0) AS DECIMAL(19,4))                  AS PlannedCost,
    CAST(ISNULL(r.ActualCost, 0) AS DECIMAL(19,4))                   AS ActualCost,
    CAST(ISNULL(r.ActualResourceHours, 0) AS DECIMAL(10,4))          AS ActualResourceHours,
    ROW_NUMBER() OVER (PARTITION BY wo.WorkOrderID ORDER BY wo.WorkOrderID) AS rn
INTO #FactProduction_Transform
FROM stg.WorkOrder wo
LEFT JOIN Routing r              ON r.WorkOrderID = wo.WorkOrderID
LEFT JOIN edw.DimProduct dp      ON dp.ProductAlternateKey = wo.ProductID
LEFT JOIN edw.DimScrapReason dsr ON dsr.ScrapReasonAlternateKey = wo.ScrapReasonID;
GO

PRINT 'VERIFYING FactProductionWorkOrder...';
SELECT COUNT(*) AS InvalidRows FROM #FactProduction_Transform WHERE OrderQuantity <= 0 OR ScrappedQuantity > OrderQuantity OR ProductionDays < 0;
SELECT COUNT(*) AS WorkOrders, SUM(OrderQuantity) AS Ordered, SUM(ScrappedQuantity) AS Scrapped,
       SUM(CASE WHEN DaysLate > 0 THEN 1 ELSE 0 END) AS LateOrders, SUM(ActualCost) AS ActualCost
FROM #FactProduction_Transform WHERE rn = 1;
GO

DECLARE @t DATETIME2(0) = SYSDATETIME(), @rc INT;
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO edw.FactProductionWorkOrder
    (
        WorkOrderNumber, ProductKey, StartDateKey, EndDateKey, DueDateKey, ScrapReasonKey, OrderQuantity, StockedQuantity,
        ScrappedQuantity, ProductionDays, DaysLate, OperationCount, PlannedCost, ActualCost, ActualResourceHours
    )
    SELECT f.WorkOrderNumber, f.ProductKey, f.StartDateKey, f.EndDateKey, f.DueDateKey, f.ScrapReasonKey, f.OrderQuantity,
           f.StockedQuantity, f.ScrappedQuantity, f.ProductionDays, f.DaysLate, f.OperationCount, f.PlannedCost, f.ActualCost,
           f.ActualResourceHours
    FROM #FactProduction_Transform f
    WHERE f.rn = 1
      AND NOT EXISTS (SELECT 1 FROM edw.FactProductionWorkOrder x WHERE x.WorkOrderNumber = f.WorkOrderNumber);
    SET @rc = @@ROWCOUNT;
    COMMIT TRANSACTION;
    EXEC etl.usp_LogStep N'Load Fact', N'edw.FactProductionWorkOrder', @rc, @t;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    DECLARE @err NVARCHAR(4000) = ERROR_MESSAGE();
    EXEC etl.usp_LogStep N'Load Fact', N'edw.FactProductionWorkOrder', 0, @t, N'Failed', @err;
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(N'%s', 16, 1, @msg);   -- show the error
    SET NOEXEC ON;                   -- stop the remaining steps so facts never load on a failed dimension
END CATCH;
GO


/*==============================================================================
    15. FACT INVENTORY TRANSACTION  (current + archive history)
==============================================================================*/
PRINT 'STEP 15: Transforming FactInventoryTransaction...';

SELECT
    th.TransactionID                                                     AS TransactionAlternateKey,
    ISNULL(CONVERT(INT, CONVERT(CHAR(8), th.TransactionDate, 112)), -1)  AS TransactionDateKey,
    ISNULL(dp.ProductKey, -1)                                            AS ProductKey,
    UPPER(th.TransactionType)                                            AS TransactionType,
    CASE UPPER(th.TransactionType) WHEN N'W' THEN N'Work Order' WHEN N'S' THEN N'Sales Order'
                                   WHEN N'P' THEN N'Purchase Order' ELSE N'Unknown' END AS TransactionTypeName,
    th.ReferenceOrderID,
    th.ReferenceOrderLineID,
    th.SourceTable,
    th.Quantity,
    th.ActualCost,
    ROW_NUMBER() OVER (PARTITION BY th.TransactionID ORDER BY th.TransactionDate DESC) AS rn
INTO #FactInvTxn_Transform
FROM stg.TransactionHistory th
LEFT JOIN edw.DimProduct dp ON dp.ProductAlternateKey = th.ProductID;
GO

SELECT TransactionTypeName, SourceTable, COUNT(*) AS Transactions, SUM(Quantity) AS Quantity
FROM #FactInvTxn_Transform WHERE rn = 1 GROUP BY TransactionTypeName, SourceTable;
SELECT TransactionAlternateKey, COUNT(*) AS Cnt FROM #FactInvTxn_Transform WHERE rn = 1
GROUP BY TransactionAlternateKey HAVING COUNT(*) > 1;
GO

DECLARE @t DATETIME2(0) = SYSDATETIME(), @rc INT;
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO edw.FactInventoryTransaction
    (
        TransactionAlternateKey, TransactionDateKey, ProductKey, TransactionType, TransactionTypeName,
        ReferenceOrderID, ReferenceOrderLineID, SourceTable, Quantity, ActualCost
    )
    SELECT f.TransactionAlternateKey, f.TransactionDateKey, f.ProductKey, f.TransactionType, f.TransactionTypeName,
           f.ReferenceOrderID, f.ReferenceOrderLineID, f.SourceTable, f.Quantity, f.ActualCost
    FROM #FactInvTxn_Transform f
    WHERE f.rn = 1
      AND NOT EXISTS (SELECT 1 FROM edw.FactInventoryTransaction x WHERE x.TransactionAlternateKey = f.TransactionAlternateKey);
    SET @rc = @@ROWCOUNT;
    COMMIT TRANSACTION;
    EXEC etl.usp_LogStep N'Load Fact', N'edw.FactInventoryTransaction', @rc, @t;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    DECLARE @err NVARCHAR(4000) = ERROR_MESSAGE();
    EXEC etl.usp_LogStep N'Load Fact', N'edw.FactInventoryTransaction', 0, @t, N'Failed', @err;
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(N'%s', 16, 1, @msg);   -- show the error
    SET NOEXEC ON;                   -- stop the remaining steps so facts never load on a failed dimension
END CATCH;
GO


/*==============================================================================
    16. FACT INVENTORY SNAPSHOT  
==============================================================================*/
PRINT 'STEP 16: Transforming FactInventorySnapshot...';

SELECT
    snap.SnapshotDateKey,
    ISNULL(dp.ProductKey, -1)   AS ProductKey,
    ISNULL(dl.LocationKey, -1)  AS LocationKey,
    etl.fn_CleanText(pi.Shelf)  AS Shelf,
    pi.Bin,
    CAST(pi.Quantity AS INT)    AS QuantityOnHand,
    ROW_NUMBER() OVER (PARTITION BY pi.ProductID, pi.LocationID ORDER BY pi.ModifiedDate DESC) AS rn
INTO #FactInvSnap_Transform
FROM stg.ProductInventory pi
CROSS JOIN (SELECT CONVERT(INT, CONVERT(CHAR(8), MAX(ModifiedDate), 112)) AS SnapshotDateKey FROM stg.ProductInventory) snap
LEFT JOIN edw.DimProduct dp  ON dp.ProductAlternateKey = pi.ProductID
LEFT JOIN edw.DimLocation dl ON dl.LocationAlternateKey = pi.LocationID;
GO

SELECT MIN(SnapshotDateKey) AS SnapshotDateKey, COUNT(*) AS Rows, SUM(QuantityOnHand) AS UnitsOnHand
FROM #FactInvSnap_Transform WHERE rn = 1;
GO

DECLARE @t DATETIME2(0) = SYSDATETIME(), @rc INT;
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO edw.FactInventorySnapshot (SnapshotDateKey, ProductKey, LocationKey, Shelf, Bin, QuantityOnHand)
    SELECT f.SnapshotDateKey, f.ProductKey, f.LocationKey, f.Shelf, f.Bin, f.QuantityOnHand
    FROM #FactInvSnap_Transform f
    WHERE f.rn = 1
      AND NOT EXISTS (SELECT 1 FROM edw.FactInventorySnapshot x
                      WHERE x.SnapshotDateKey = f.SnapshotDateKey AND x.ProductKey = f.ProductKey AND x.LocationKey = f.LocationKey);
    SET @rc = @@ROWCOUNT;
    COMMIT TRANSACTION;
    EXEC etl.usp_LogStep N'Load Fact', N'edw.FactInventorySnapshot', @rc, @t;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    DECLARE @err NVARCHAR(4000) = ERROR_MESSAGE();
    EXEC etl.usp_LogStep N'Load Fact', N'edw.FactInventorySnapshot', 0, @t, N'Failed', @err;
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(N'%s', 16, 1, @msg);   -- show the error
    SET NOEXEC ON;                   -- stop the remaining steps so facts never load on a failed dimension
END CATCH;
GO


/*==============================================================================
    17. FACT CURRENCY RATE  
==============================================================================*/
PRINT 'STEP 17: Transforming FactCurrencyRate...';

SELECT
    ISNULL(dcu.CurrencyKey, -1)                                          AS CurrencyKey,
    ISNULL(CONVERT(INT, CONVERT(CHAR(8), cr.CurrencyRateDate, 112)), -1) AS DateKey,
    cr.AverageRate,
    cr.EndOfDayRate,
    ROW_NUMBER() OVER (PARTITION BY cr.ToCurrencyCode, CAST(cr.CurrencyRateDate AS DATE) ORDER BY cr.CurrencyRateID DESC) AS rn
INTO #FactCurrencyRate_Transform
FROM stg.CurrencyRate cr
LEFT JOIN edw.DimCurrency dcu ON dcu.CurrencyAlternateKey = cr.ToCurrencyCode
WHERE cr.FromCurrencyCode = N'USD';
GO

SELECT COUNT(*) AS RateRows, COUNT(DISTINCT CurrencyKey) AS Currencies,
       SUM(CASE WHEN AverageRate <= 0 OR EndOfDayRate <= 0 THEN 1 ELSE 0 END) AS InvalidRates
FROM #FactCurrencyRate_Transform WHERE rn = 1;
GO

DECLARE @t DATETIME2(0) = SYSDATETIME(), @rc INT;
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO edw.FactCurrencyRate (CurrencyKey, DateKey, AverageRate, EndOfDayRate)
    SELECT f.CurrencyKey, f.DateKey, f.AverageRate, f.EndOfDayRate
    FROM #FactCurrencyRate_Transform f
    WHERE f.rn = 1
      AND NOT EXISTS (SELECT 1 FROM edw.FactCurrencyRate x WHERE x.CurrencyKey = f.CurrencyKey AND x.DateKey = f.DateKey);
    SET @rc = @@ROWCOUNT;
    COMMIT TRANSACTION;
    EXEC etl.usp_LogStep N'Load Fact', N'edw.FactCurrencyRate', @rc, @t;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    DECLARE @err NVARCHAR(4000) = ERROR_MESSAGE();
    EXEC etl.usp_LogStep N'Load Fact', N'edw.FactCurrencyRate', 0, @t, N'Failed', @err;
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(N'%s', 16, 1, @msg);   -- show the error
    SET NOEXEC ON;                   -- stop the remaining steps so facts never load on a failed dimension
END CATCH;
GO


/*==============================================================================
    18. FINAL POST-LOAD VERIFICATION
==============================================================================*/
PRINT 'FINAL FACT TABLE VERIFICATION';

SELECT 'FactSales' AS FactTable, COUNT(*) AS RowCnt FROM edw.FactSales
UNION ALL SELECT 'FactSalesReason',          COUNT(*) FROM edw.FactSalesReason
UNION ALL SELECT 'FactSalesQuota',           COUNT(*) FROM edw.FactSalesQuota
UNION ALL SELECT 'FactPurchases',            COUNT(*) FROM edw.FactPurchases
UNION ALL SELECT 'FactProductionWorkOrder',  COUNT(*) FROM edw.FactProductionWorkOrder
UNION ALL SELECT 'FactInventoryTransaction', COUNT(*) FROM edw.FactInventoryTransaction
UNION ALL SELECT 'FactInventorySnapshot',    COUNT(*) FROM edw.FactInventorySnapshot
UNION ALL SELECT 'FactCurrencyRate',         COUNT(*) FROM edw.FactCurrencyRate;

-- Sales by channel after load
SELECT SalesChannel, COUNT(*) AS Lines, COUNT(DISTINCT SalesOrderNumber) AS Orders,
       SUM(SalesAmount) AS SalesAmount, SUM(GrossProfit) AS GrossProfit
FROM edw.FactSales GROUP BY SalesChannel;

-- Execution log for this run
SELECT LogID, ProcessName, TargetTable, RowsProcessed, Status, ExecutionStartTime, ExecutionEndTime
FROM etl.ExecutionLog ORDER BY LogID;

PRINT 'ETL PROCESS COMPLETED';
GO

SET NOEXEC OFF;   -- re-enable execution (it is switched on only if a step failed)
GO

SELECT *
FROM edw.FactPurchases;