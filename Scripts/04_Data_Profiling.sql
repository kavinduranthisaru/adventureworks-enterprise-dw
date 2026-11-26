USE AdventureWorks_DW;
GO
SET NOCOUNT ON;
GO

/*==============================================================================
    1. COLUMN PROFILING
==============================================================================*/

-- 1.1 Missing values in the product CSV (NULL, blank or the text 'NULL')
SELECT 'stg.Product' AS TableName,
       COUNT(*) AS TotalRows,
       SUM(CASE WHEN etl.fn_CleanText(Color)                IS NULL THEN 1 ELSE 0 END) AS MissingColor,
       SUM(CASE WHEN etl.fn_CleanText(Size)                 IS NULL THEN 1 ELSE 0 END) AS MissingSize,
       SUM(CASE WHEN etl.fn_CleanText(Weight)               IS NULL THEN 1 ELSE 0 END) AS MissingWeight,
       SUM(CASE WHEN etl.fn_CleanText(ProductSubcategoryID) IS NULL THEN 1 ELSE 0 END) AS MissingSubcategory,
       SUM(CASE WHEN etl.fn_CleanText(ProductModelID)       IS NULL THEN 1 ELSE 0 END) AS MissingModel,
       SUM(CASE WHEN etl.fn_CleanText(ProductLine)          IS NULL THEN 1 ELSE 0 END) AS MissingProductLine,
       CAST(SUM(CASE WHEN etl.fn_CleanText(Color) IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS MissingColorPct
FROM stg.Product;

-- 1.2 Date columns in the CSV were damaged by the spreadsheet export (e.g. '00:00.0')
SELECT 'stg.Product' AS TableName,
       SUM(CASE WHEN ISNULL(TRY_CONVERT(DATE, etl.fn_CleanText(SellStartDate)), '19000101') = '19000101' THEN 1 ELSE 0 END) AS UnusableSellStartDate,
       SUM(CASE WHEN ISNULL(TRY_CONVERT(DATE, etl.fn_CleanText(ModifiedDate)),  '19000101') = '19000101' THEN 1 ELSE 0 END) AS UnusableModifiedDate,
       COUNT(*) AS TotalRows
FROM stg.Product;

-- 1.3 Trailing spaces in code columns (e.g. 'R ', 'CM ')
SELECT 'stg.Product' AS TableName,
       SUM(CASE WHEN ProductLine <> LTRIM(RTRIM(ProductLine)) THEN 1 ELSE 0 END)                 AS ProductLineWithSpaces,
       SUM(CASE WHEN SizeUnitMeasureCode <> LTRIM(RTRIM(SizeUnitMeasureCode)) THEN 1 ELSE 0 END) AS SizeUnitWithSpaces
FROM stg.Product;

-- 1.4 Customer names and demographics
SELECT 'stg.Person' AS TableName,
       COUNT(*) AS TotalRows,
       SUM(CASE WHEN FirstName IS NULL THEN 1 ELSE 0 END)    AS MissingFirstNames,
       SUM(CASE WHEN LastName  IS NULL THEN 1 ELSE 0 END)    AS MissingLastNames,
       SUM(CASE WHEN MiddleName IS NULL THEN 1 ELSE 0 END)   AS MissingMiddleNames,
       SUM(CASE WHEN Demographics IS NULL THEN 1 ELSE 0 END) AS MissingDemographics
FROM stg.Person;

-- 1.5 Distinct values of coded columns
SELECT 'stg.Person.PersonType' AS ColumnName, PersonType AS Value, COUNT(*) AS Cnt FROM stg.Person GROUP BY PersonType
UNION ALL
SELECT 'stg.SalesOrderHeader.OnlineOrderFlag', CAST(OnlineOrderFlag AS NVARCHAR(10)), COUNT(*) FROM stg.SalesOrderHeader GROUP BY OnlineOrderFlag
UNION ALL
SELECT 'stg.TransactionHistory.TransactionType', TransactionType, COUNT(*) FROM stg.TransactionHistory GROUP BY TransactionType
UNION ALL
SELECT 'stg.PurchaseOrderHeader.Status', CAST(Status AS NVARCHAR(10)), COUNT(*) FROM stg.PurchaseOrderHeader GROUP BY Status
ORDER BY ColumnName, Value;

-- 1.6 Optional foreign keys that are often empty
SELECT 'stg.SalesOrderHeader' AS TableName,
       SUM(CASE WHEN SalesPersonID  IS NULL THEN 1 ELSE 0 END) AS NoSalesPerson,
       SUM(CASE WHEN CurrencyRateID IS NULL THEN 1 ELSE 0 END) AS NoCurrencyRate,
       COUNT(*) AS TotalRows
FROM stg.SalesOrderHeader;

SELECT 'stg.WorkOrder' AS TableName,
       SUM(CASE WHEN ScrapReasonID IS NULL THEN 1 ELSE 0 END) AS NoScrapReason,
       SUM(CASE WHEN EndDate      IS NULL THEN 1 ELSE 0 END) AS NoEndDate,
       COUNT(*) AS TotalRows
FROM stg.WorkOrder;


/*==============================================================================
    2. STATISTICAL ANALYSIS
==============================================================================*/

SELECT 'stg.Product.StandardCost' AS Measure,
       MIN(TRY_CAST(StandardCost AS DECIMAL(19,4))) AS MinValue,
       MAX(TRY_CAST(StandardCost AS DECIMAL(19,4))) AS MaxValue,
       AVG(TRY_CAST(StandardCost AS DECIMAL(19,4))) AS AvgValue
FROM stg.Product
UNION ALL
SELECT 'stg.Product.ListPrice',
       MIN(TRY_CAST(ListPrice AS DECIMAL(19,4))), MAX(TRY_CAST(ListPrice AS DECIMAL(19,4))), AVG(TRY_CAST(ListPrice AS DECIMAL(19,4)))
FROM stg.Product
UNION ALL
SELECT 'stg.SalesOrderDetail.OrderQty', MIN(OrderQty), MAX(OrderQty), AVG(CAST(OrderQty AS DECIMAL(19,4))) FROM stg.SalesOrderDetail
UNION ALL
SELECT 'stg.SalesOrderDetail.UnitPrice', MIN(UnitPrice), MAX(UnitPrice), AVG(UnitPrice) FROM stg.SalesOrderDetail
UNION ALL
SELECT 'stg.PurchaseOrderDetail.OrderQty', MIN(OrderQty), MAX(OrderQty), AVG(CAST(OrderQty AS DECIMAL(19,4))) FROM stg.PurchaseOrderDetail
UNION ALL
SELECT 'stg.WorkOrder.ScrappedQty', MIN(ScrappedQty), MAX(ScrappedQty), AVG(CAST(ScrappedQty AS DECIMAL(19,4))) FROM stg.WorkOrder
UNION ALL
SELECT 'stg.TransactionHistory.Quantity', MIN(Quantity), MAX(Quantity), AVG(CAST(Quantity AS DECIMAL(19,4))) FROM stg.TransactionHistory;

-- Date coverage of each business process (drives the DimDate range)
SELECT 'Sales orders' AS Process, MIN(OrderDate) AS FirstDate, MAX(ShipDate) AS LastDate FROM stg.SalesOrderHeader
UNION ALL SELECT 'Purchase orders', MIN(OrderDate), MAX(ISNULL(ShipDate, OrderDate)) FROM stg.PurchaseOrderHeader
UNION ALL SELECT 'Work orders', MIN(StartDate), MAX(ISNULL(EndDate, DueDate)) FROM stg.WorkOrder
UNION ALL SELECT 'Inventory transactions', MIN(TransactionDate), MAX(TransactionDate) FROM stg.TransactionHistory
UNION ALL SELECT 'Currency rates', MIN(CurrencyRateDate), MAX(CurrencyRateDate) FROM stg.CurrencyRate
UNION ALL SELECT 'Sales quotas', MIN(QuotaDate), MAX(QuotaDate) FROM stg.SalesPersonQuotaHistory;


/*==============================================================================
    3. CROSS-COLUMN PROFILING
==============================================================================*/

SELECT 'stg.SpecialOffer' AS TableName, 'End date before start date' AS RuleName,
       SUM(CASE WHEN TRY_CONVERT(DATETIME, EndDate) < TRY_CONVERT(DATETIME, StartDate) THEN 1 ELSE 0 END) AS FailedRows
FROM stg.SpecialOffer
UNION ALL
SELECT 'stg.SalesOrderDetail', 'Discount greater than price',
       SUM(CASE WHEN UnitPriceDiscount > UnitPrice THEN 1 ELSE 0 END) FROM stg.SalesOrderDetail
UNION ALL
SELECT 'stg.SalesOrderDetail', 'LineTotal <> Qty x Price x (1 - Discount)',
       SUM(CASE WHEN ABS(LineTotal - OrderQty * UnitPrice * (1 - UnitPriceDiscount)) > 0.01 THEN 1 ELSE 0 END) FROM stg.SalesOrderDetail
UNION ALL
SELECT 'stg.SalesOrderHeader', 'Ship date before order date',
       SUM(CASE WHEN ShipDate < OrderDate THEN 1 ELSE 0 END) FROM stg.SalesOrderHeader
UNION ALL
SELECT 'stg.PurchaseOrderDetail', 'Rejected quantity greater than received',
       SUM(CASE WHEN RejectedQty > ReceivedQty THEN 1 ELSE 0 END) FROM stg.PurchaseOrderDetail
UNION ALL
SELECT 'stg.WorkOrder', 'End date before start date',
       SUM(CASE WHEN EndDate < StartDate THEN 1 ELSE 0 END) FROM stg.WorkOrder
UNION ALL
SELECT 'stg.WorkOrder', 'Scrapped quantity greater than ordered',
       SUM(CASE WHEN ScrappedQty > OrderQty THEN 1 ELSE 0 END) FROM stg.WorkOrder;


/*==============================================================================
    4. CROSS-TABLE PROFILING (referential integrity across sources)
==============================================================================*/

SELECT 'stg.Product (CSV) -> stg.ProductSubcategory (CSV)' AS Relationship,
       COUNT(*) AS OrphanRows
FROM stg.Product p
LEFT JOIN stg.ProductSubcategory ps
       ON TRY_CAST(etl.fn_CleanText(p.ProductSubcategoryID) AS INT) = TRY_CAST(ps.ProductSubcategoryID AS INT)
WHERE etl.fn_CleanText(p.ProductSubcategoryID) IS NOT NULL AND ps.ProductSubcategoryID IS NULL
UNION ALL
SELECT 'stg.SalesOrderDetail (DB) -> stg.Product (CSV)', COUNT(*)
FROM stg.SalesOrderDetail sod
LEFT JOIN stg.Product p ON TRY_CAST(p.ProductID AS INT) = sod.ProductID
WHERE p.ProductID IS NULL
UNION ALL
SELECT 'stg.SalesOrderHeader (DB) -> stg.SalesTerritory (JSON)', COUNT(*)
FROM stg.SalesOrderHeader soh
LEFT JOIN stg.SalesTerritory st ON st.TerritoryID = soh.TerritoryID
WHERE st.TerritoryID IS NULL
UNION ALL
SELECT 'stg.SalesOrderDetail (DB) -> stg.SpecialOffer (XML)', COUNT(*)
FROM stg.SalesOrderDetail sod
LEFT JOIN stg.SpecialOffer so ON so.SpecialOfferID = sod.SpecialOfferID
WHERE so.SpecialOfferID IS NULL
UNION ALL
SELECT 'stg.SalesOrderHeader -> stg.Customer', COUNT(*)
FROM stg.SalesOrderHeader soh
LEFT JOIN stg.Customer c ON c.CustomerID = soh.CustomerID
WHERE c.CustomerID IS NULL
UNION ALL
SELECT 'stg.PurchaseOrderDetail -> stg.Product (CSV)', COUNT(*)
FROM stg.PurchaseOrderDetail pod
LEFT JOIN stg.Product p ON TRY_CAST(p.ProductID AS INT) = pod.ProductID
WHERE p.ProductID IS NULL
UNION ALL
SELECT 'Individual customers without any address', COUNT(*)
FROM stg.Customer c
WHERE c.PersonID IS NOT NULL AND c.StoreID IS NULL
  AND NOT EXISTS (SELECT 1 FROM stg.BusinessEntityAddress bea WHERE bea.BusinessEntityID = c.PersonID)
UNION ALL
SELECT 'Sales order lines with no cost history for the order date', COUNT(*)
FROM stg.SalesOrderDetail sod
JOIN stg.SalesOrderHeader soh ON soh.SalesOrderID = sod.SalesOrderID
WHERE NOT EXISTS (SELECT 1 FROM stg.ProductCostHistory pch
                  WHERE pch.ProductID = sod.ProductID AND pch.StartDate <= soh.OrderDate);


/*==============================================================================
    5. DATA RULE VALIDATION
==============================================================================*/

SELECT 'stg.Person' AS TableName, 'EmailPromotion must be 0, 1 or 2' AS RuleName,
       SUM(CASE WHEN EmailPromotion NOT IN (0, 1, 2) THEN 1 ELSE 0 END) AS FailedRows FROM stg.Person
UNION ALL
SELECT 'stg.SpecialOffer', 'DiscountPct must be between 0 and 1',
       SUM(CASE WHEN TRY_CAST(DiscountPct AS DECIMAL(10,4)) NOT BETWEEN 0 AND 1 THEN 1 ELSE 0 END) FROM stg.SpecialOffer
UNION ALL
SELECT 'stg.SalesOrderDetail', 'OrderQty must be positive',
       SUM(CASE WHEN OrderQty <= 0 THEN 1 ELSE 0 END) FROM stg.SalesOrderDetail
UNION ALL
SELECT 'stg.Vendor', 'CreditRating must be 1 to 5',
       SUM(CASE WHEN CreditRating NOT BETWEEN 1 AND 5 THEN 1 ELSE 0 END) FROM stg.Vendor
UNION ALL
SELECT 'stg.SalesOrderDetail', 'Duplicate order lines',
       COUNT(*) - COUNT(DISTINCT CONCAT(SalesOrderID, '-', SalesOrderDetailID)) FROM stg.SalesOrderDetail
UNION ALL
SELECT 'stg.Product', 'Duplicate ProductID',
       COUNT(*) - COUNT(DISTINCT etl.fn_CleanText(ProductID)) FROM stg.Product
UNION ALL
SELECT 'stg.BusinessEntityAddress', 'Entities with more than one address',
       COUNT(*) FROM (SELECT BusinessEntityID FROM stg.BusinessEntityAddress GROUP BY BusinessEntityID HAVING COUNT(*) > 1) x;
GO

PRINT 'Script 04 completed: profiling results returned above.';
GO
