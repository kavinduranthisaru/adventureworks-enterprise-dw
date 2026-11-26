USE AdventureWorks_DW;
GO
SET NOCOUNT ON;
GO

DECLARE @RunStart DATETIME2(0) = SYSDATETIME();

/*------------------------------------------------------------------------------
    1. RECONCILIATION: ROW COUNTS (source vs EDW)
------------------------------------------------------------------------------*/
INSERT INTO etl.DataQualityResult (CheckGroup, TableName, CheckName, ExpectedValue, ActualValue)
SELECT N'Reconciliation', N'edw.FactSales', N'Rows = source order lines',
       (SELECT COUNT(*) FROM AdventureWorks2022.Sales.SalesOrderDetail), (SELECT COUNT(*) FROM edw.FactSales)
UNION ALL
SELECT N'Reconciliation', N'edw.FactSales', N'Internet rows = source online order lines',
       (SELECT COUNT(*) FROM AdventureWorks2022.Sales.SalesOrderDetail d
        JOIN AdventureWorks2022.Sales.SalesOrderHeader h ON h.SalesOrderID = d.SalesOrderID WHERE h.OnlineOrderFlag = 1),
       (SELECT COUNT(*) FROM edw.FactSales WHERE SalesChannel = N'Internet')
UNION ALL
SELECT N'Reconciliation', N'edw.FactSalesReason', N'Rows = source order reasons',
       (SELECT COUNT(*) FROM AdventureWorks2022.Sales.SalesOrderHeaderSalesReason), (SELECT COUNT(*) FROM edw.FactSalesReason)
UNION ALL
SELECT N'Reconciliation', N'edw.FactSalesQuota', N'Rows = source quota history',
       (SELECT COUNT(*) FROM AdventureWorks2022.Sales.SalesPersonQuotaHistory), (SELECT COUNT(*) FROM edw.FactSalesQuota)
UNION ALL
SELECT N'Reconciliation', N'edw.FactPurchases', N'Rows = source purchase order lines',
       (SELECT COUNT(*) FROM AdventureWorks2022.Purchasing.PurchaseOrderDetail), (SELECT COUNT(*) FROM edw.FactPurchases)
UNION ALL
SELECT N'Reconciliation', N'edw.FactProductionWorkOrder', N'Rows = source work orders',
       (SELECT COUNT(*) FROM AdventureWorks2022.Production.WorkOrder), (SELECT COUNT(*) FROM edw.FactProductionWorkOrder)
UNION ALL
SELECT N'Reconciliation', N'edw.FactInventoryTransaction', N'Rows = source transactions (current + archive)',
       (SELECT COUNT(*) FROM AdventureWorks2022.Production.TransactionHistory)
     + (SELECT COUNT(*) FROM AdventureWorks2022.Production.TransactionHistoryArchive),
       (SELECT COUNT(*) FROM edw.FactInventoryTransaction)
UNION ALL
SELECT N'Reconciliation', N'edw.FactInventorySnapshot', N'Rows = source product inventory',
       (SELECT COUNT(*) FROM AdventureWorks2022.Production.ProductInventory), (SELECT COUNT(*) FROM edw.FactInventorySnapshot)
UNION ALL
SELECT N'Reconciliation', N'edw.FactCurrencyRate', N'Rows = source USD currency rates',
       (SELECT COUNT(*) FROM AdventureWorks2022.Sales.CurrencyRate WHERE FromCurrencyCode = N'USD'), (SELECT COUNT(*) FROM edw.FactCurrencyRate)
UNION ALL
SELECT N'Reconciliation', N'edw.DimProduct', N'Members = CSV products (+1 Unknown)',
       (SELECT COUNT(*) FROM stg.Product) + 1, (SELECT COUNT(*) FROM edw.DimProduct)
UNION ALL
SELECT N'Reconciliation', N'edw.DimTerritory', N'Members = JSON territories (+1 Unknown)',
       (SELECT COUNT(*) FROM stg.SalesTerritory) + 1, (SELECT COUNT(*) FROM edw.DimTerritory)
UNION ALL
SELECT N'Reconciliation', N'edw.DimPromotion', N'Members = XML promotions (+1 Unknown)',
       (SELECT COUNT(*) FROM stg.SpecialOffer) + 1, (SELECT COUNT(*) FROM edw.DimPromotion)
UNION ALL
SELECT N'Reconciliation', N'edw.DimCustomer', N'Members = individual customers (+1 Unknown)',
       (SELECT COUNT(*) FROM AdventureWorks2022.Sales.Customer WHERE PersonID IS NOT NULL AND StoreID IS NULL) + 1,
       (SELECT COUNT(*) FROM edw.DimCustomer)
UNION ALL
SELECT N'Reconciliation', N'edw.DimReseller', N'Members = stores (+1 Unknown)',
       (SELECT COUNT(*) FROM AdventureWorks2022.Sales.Store) + 1, (SELECT COUNT(*) FROM edw.DimReseller)
UNION ALL
SELECT N'Reconciliation', N'edw.DimEmployee', N'Members = employees (+1 Unknown)',
       (SELECT COUNT(*) FROM AdventureWorks2022.HumanResources.Employee) + 1, (SELECT COUNT(*) FROM edw.DimEmployee)
UNION ALL
SELECT N'Reconciliation', N'edw.DimVendor', N'Members = vendors (+1 Unknown)',
       (SELECT COUNT(*) FROM AdventureWorks2022.Purchasing.Vendor) + 1, (SELECT COUNT(*) FROM edw.DimVendor);


/*------------------------------------------------------------------------------
    2. RECONCILIATION: MONEY TOTALS (source vs EDW)
------------------------------------------------------------------------------*/
INSERT INTO etl.DataQualityResult (CheckGroup, TableName, CheckName, ExpectedValue, ActualValue)
SELECT N'Reconciliation', N'edw.FactSales', N'SalesAmount = source LineTotal',
       (SELECT SUM(LineTotal) FROM AdventureWorks2022.Sales.SalesOrderDetail), (SELECT SUM(SalesAmount) FROM edw.FactSales)
UNION ALL
SELECT N'Reconciliation', N'edw.FactSales', N'Internet SalesAmount = source online LineTotal',
       (SELECT SUM(d.LineTotal) FROM AdventureWorks2022.Sales.SalesOrderDetail d
        JOIN AdventureWorks2022.Sales.SalesOrderHeader h ON h.SalesOrderID = d.SalesOrderID WHERE h.OnlineOrderFlag = 1),
       (SELECT SUM(SalesAmount) FROM edw.FactSales WHERE SalesChannel = N'Internet')
UNION ALL
SELECT N'Reconciliation', N'edw.FactSales', N'Allocated TaxAmount = source header TaxAmt',
       (SELECT SUM(TaxAmt) FROM AdventureWorks2022.Sales.SalesOrderHeader), (SELECT SUM(TaxAmount) FROM edw.FactSales)
UNION ALL
SELECT N'Reconciliation', N'edw.FactSales', N'Allocated FreightAmount = source header Freight',
       (SELECT SUM(Freight) FROM AdventureWorks2022.Sales.SalesOrderHeader), (SELECT SUM(FreightAmount) FROM edw.FactSales)
UNION ALL
SELECT N'Reconciliation', N'edw.FactPurchases', N'LineTotal = source PO LineTotal',
       (SELECT SUM(LineTotal) FROM AdventureWorks2022.Purchasing.PurchaseOrderDetail), (SELECT SUM(LineTotal) FROM edw.FactPurchases)
UNION ALL
SELECT N'Reconciliation', N'edw.FactSalesQuota', N'Quota total = source quota total',
       (SELECT SUM(SalesQuota) FROM AdventureWorks2022.Sales.SalesPersonQuotaHistory), (SELECT SUM(SalesAmountQuota) FROM edw.FactSalesQuota);


/*------------------------------------------------------------------------------
    3. UNIQUENESS: duplicate grain (expected 0)
------------------------------------------------------------------------------*/
INSERT INTO etl.DataQualityResult (CheckGroup, TableName, CheckName, ExpectedValue, ActualValue)
SELECT N'Uniqueness', N'edw.FactSales', N'Duplicate order + line', 0,
       (SELECT COUNT(*) FROM (SELECT SalesOrderNumber, SalesOrderLineNumber FROM edw.FactSales
                              GROUP BY SalesOrderNumber, SalesOrderLineNumber HAVING COUNT(*) > 1) x)
UNION ALL
SELECT N'Uniqueness', N'edw.FactPurchases', N'Duplicate PO + line', 0,
       (SELECT COUNT(*) FROM (SELECT PurchaseOrderNumber, PurchaseOrderLineNumber FROM edw.FactPurchases
                              GROUP BY PurchaseOrderNumber, PurchaseOrderLineNumber HAVING COUNT(*) > 1) x)
UNION ALL
SELECT N'Uniqueness', N'edw.DimCustomer', N'Duplicate business key', 0,
       (SELECT COUNT(*) - COUNT(DISTINCT CustomerAlternateKey) FROM edw.DimCustomer);


/*------------------------------------------------------------------------------
    4. INTEGRITY: rows that fell back to the Unknown member (expected 0)
------------------------------------------------------------------------------*/
INSERT INTO etl.DataQualityResult (CheckGroup, TableName, CheckName, ExpectedValue, ActualValue)
SELECT N'Integrity', N'edw.FactSales', N'Lines with Unknown product', 0, (SELECT COUNT(*) FROM edw.FactSales WHERE ProductKey = -1)
UNION ALL
SELECT N'Integrity', N'edw.FactSales', N'Internet lines with Unknown customer', 0,
       (SELECT COUNT(*) FROM edw.FactSales WHERE SalesChannel = N'Internet' AND CustomerKey = -1)
UNION ALL
SELECT N'Integrity', N'edw.FactSales', N'Reseller lines with Unknown reseller', 0,
       (SELECT COUNT(*) FROM edw.FactSales WHERE SalesChannel = N'Reseller' AND ResellerKey = -1)
UNION ALL
SELECT N'Integrity', N'edw.FactSales', N'Lines with Unknown territory', 0, (SELECT COUNT(*) FROM edw.FactSales WHERE TerritoryKey = -1)
UNION ALL
SELECT N'Integrity', N'edw.FactSales', N'Lines with Unknown promotion', 0, (SELECT COUNT(*) FROM edw.FactSales WHERE PromotionKey = -1)
UNION ALL
SELECT N'Integrity', N'edw.FactSales', N'Lines with Unknown order date', 0, (SELECT COUNT(*) FROM edw.FactSales WHERE OrderDateKey = -1)
UNION ALL
SELECT N'Integrity', N'edw.FactPurchases', N'Lines with Unknown vendor', 0, (SELECT COUNT(*) FROM edw.FactPurchases WHERE VendorKey = -1)
UNION ALL
SELECT N'Integrity', N'edw.FactProductionWorkOrder', N'Work orders with Unknown product', 0,
       (SELECT COUNT(*) FROM edw.FactProductionWorkOrder WHERE ProductKey = -1)
UNION ALL
SELECT N'Integrity', N'edw.FactInventoryTransaction', N'Transactions with Unknown product', 0,
       (SELECT COUNT(*) FROM edw.FactInventoryTransaction WHERE ProductKey = -1)
UNION ALL
SELECT N'Integrity', N'edw.DimEmployee', N'Employees without a manager (expected 1: CEO)', 1,
       (SELECT COUNT(*) FROM edw.DimEmployee WHERE EmployeeKey <> -1 AND ParentEmployeeKey IS NULL);


/*------------------------------------------------------------------------------
    5. COMPLETENESS: invalid measures (expected 0)
------------------------------------------------------------------------------*/
INSERT INTO etl.DataQualityResult (CheckGroup, TableName, CheckName, ExpectedValue, ActualValue)
SELECT N'Completeness', N'edw.FactSales', N'Lines with quantity <= 0 or negative amounts', 0,
       (SELECT COUNT(*) FROM edw.FactSales WHERE OrderQuantity <= 0 OR SalesAmount < 0 OR TotalProductCost < 0)
UNION ALL
SELECT N'Completeness', N'edw.FactSales', N'Lines with zero product cost', 0,
       (SELECT COUNT(*) FROM edw.FactSales WHERE ProductStandardCost = 0)
UNION ALL
SELECT N'Completeness', N'edw.FactPurchases', N'Lines with rejected > received', 0,
       (SELECT COUNT(*) FROM edw.FactPurchases WHERE RejectedQuantity > ReceivedQuantity);


/*------------------------------------------------------------------------------
    6. RESULTS OF THIS RUN
------------------------------------------------------------------------------*/
SELECT CheckGroup, TableName, CheckName, ExpectedValue, ActualValue, Status
FROM etl.DataQualityResult
WHERE CheckTime >= @RunStart
ORDER BY CASE Status WHEN N'FAIL' THEN 0 ELSE 1 END, CheckGroup, TableName;

SELECT Status, COUNT(*) AS Checks
FROM etl.DataQualityResult
WHERE CheckTime >= @RunStart
GROUP BY Status;

PRINT 'Script 07 completed: validation results stored in etl.DataQualityResult.';
GO
