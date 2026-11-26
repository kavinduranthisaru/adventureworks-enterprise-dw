USE AdventureWorks2022;
GO

/*------------------------------------------------------------------------------
    1. CSV EXPORTS (product catalogue)
------------------------------------------------------------------------------*/
SELECT * FROM Production.Product;
SELECT * FROM Production.ProductSubcategory;
SELECT * FROM Production.ProductCategory;
GO

/*------------------------------------------------------------------------------
    2. JSON EXPORT (territory feed) 
------------------------------------------------------------------------------*/
SELECT
    TerritoryID,
    Name      AS RegionName,
    CountryRegionCode,
    [Group]   AS TerritoryGroup
FROM Sales.SalesTerritory
FOR JSON PATH, ROOT('Territories');
GO

/*------------------------------------------------------------------------------
    3. XML EXPORT (promotions) 
------------------------------------------------------------------------------*/
SELECT
    SpecialOfferID,
    Description,
    DiscountPct,
    Type,
    Category,
    StartDate,
    EndDate
FROM Sales.SpecialOffer
FOR XML PATH('Promotion'), ROOT('Promotions');
GO

/*------------------------------------------------------------------------------
    4. SOURCE INVENTORY
------------------------------------------------------------------------------*/
SELECT s.name AS SchemaName, t.name AS TableName, SUM(p.rows) AS RowCnt
FROM sys.tables t
JOIN sys.schemas s     ON s.schema_id = t.schema_id
JOIN sys.partitions p  ON p.object_id = t.object_id AND p.index_id IN (0, 1)
WHERE s.name + '.' + t.name IN
(
    'Sales.SalesOrderHeader','Sales.SalesOrderDetail','Sales.Customer','Sales.Store',
    'Sales.SalesPerson','Sales.SalesPersonQuotaHistory','Sales.SalesReason',
    'Sales.SalesOrderHeaderSalesReason','Sales.Currency','Sales.CurrencyRate',
    'Person.Person','Person.Address','Person.BusinessEntityAddress','Person.StateProvince',
    'Person.CountryRegion','HumanResources.Employee','HumanResources.EmployeeDepartmentHistory',
    'HumanResources.Department','HumanResources.Shift','Purchasing.Vendor',
    'Purchasing.PurchaseOrderHeader','Purchasing.PurchaseOrderDetail','Purchasing.ShipMethod',
    'Production.ProductModel','Production.ProductCostHistory','Production.WorkOrder',
    'Production.WorkOrderRouting','Production.ScrapReason','Production.Location',
    'Production.ProductInventory','Production.TransactionHistory','Production.TransactionHistoryArchive',
    'Production.Product','Production.ProductSubcategory','Production.ProductCategory',
    'Sales.SalesTerritory','Sales.SpecialOffer'
)
GROUP BY s.name, t.name
ORDER BY s.name, t.name;
GO
