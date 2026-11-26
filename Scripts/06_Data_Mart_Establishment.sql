USE AdventureWorks_DW;
GO


/*==============================================================================
    1. INTERNET SALES DATA MART  (dm_internet_sales)
==============================================================================*/

CREATE OR ALTER VIEW dm_internet_sales.FactInternetSales AS
SELECT
    SalesOrderLineKey, SalesOrderNumber, SalesOrderLineNumber,
    OrderDateKey, DueDateKey, ShipDateKey,
    ProductKey, CustomerKey, TerritoryKey, PromotionKey, ShipMethodKey, CurrencyKey,
    OrderQuantity, UnitPrice, ExtendedAmount, UnitPriceDiscountPct, DiscountAmount, SalesAmount,
    ProductStandardCost, TotalProductCost, GrossProfit, TaxAmount, FreightAmount
FROM edw.FactSales
WHERE SalesChannel = N'Internet';       -- e-commerce transactions only
GO

CREATE OR ALTER VIEW dm_internet_sales.FactInternetSalesReason AS
SELECT r.SalesOrderNumber, r.SalesReasonKey, r.OrderDateKey, r.CustomerKey, r.TerritoryKey
FROM edw.FactSalesReason r
WHERE EXISTS (SELECT 1 FROM edw.FactSales fs
              WHERE fs.SalesOrderNumber = r.SalesOrderNumber AND fs.SalesChannel = N'Internet');
GO

CREATE OR ALTER VIEW dm_internet_sales.DimDate AS
SELECT DateKey, FullDate, DayNumberOfWeek, EnglishDayNameOfWeek, DayNumberOfMonth, WeekNumberOfYear,
       EnglishMonthName, MonthNumberOfYear, CalendarQuarter, CalendarSemester, CalendarYear,
       YearMonthKey, MonthYearLabel, QuarterLabel, FiscalQuarter, FiscalYear, IsWeekend
FROM edw.DimDate;
GO

-- Only products that were sold online (plus Unknown), so slicers stay clean
CREATE OR ALTER VIEW dm_internet_sales.DimProduct AS
SELECT p.ProductKey, p.ProductAlternateKey, p.ProductNumber, p.ProductName, p.Color, p.Size, p.StandardCost, p.ListPrice,
       p.ProductLine, p.Class, p.Style, p.ProductModelName, p.SubcategoryName, p.CategoryName
FROM edw.DimProduct p
WHERE p.ProductKey = -1
   OR EXISTS (SELECT 1 FROM edw.FactSales fs WHERE fs.ProductKey = p.ProductKey AND fs.SalesChannel = N'Internet');
GO

CREATE OR ALTER VIEW dm_internet_sales.DimCustomer AS
SELECT c.CustomerKey, c.CustomerAlternateKey, c.FullName, c.FirstName, c.LastName, c.BirthDate, c.AgeGroup, c.Gender,
       c.MaritalStatus, c.YearlyIncome, c.TotalChildren, c.Education, c.Occupation, c.HomeOwnerFlag, c.NumberCarsOwned,
       c.CommuteDistance, c.DateFirstPurchase, c.EmailPromotion, c.EmailPromotionDesc,
       c.City, c.StateProvinceName, c.PostalCode, c.CountryRegionCode, c.CountryRegionName
FROM edw.DimCustomer c
WHERE c.CustomerKey = -1
   OR EXISTS (SELECT 1 FROM edw.FactSales fs WHERE fs.CustomerKey = c.CustomerKey AND fs.SalesChannel = N'Internet');
GO

CREATE OR ALTER VIEW dm_internet_sales.DimTerritory AS
SELECT TerritoryKey, TerritoryAlternateKey, RegionName, CountryRegionCode, TerritoryGroup
FROM edw.DimTerritory;
GO

CREATE OR ALTER VIEW dm_internet_sales.DimPromotion AS
SELECT p.PromotionKey, p.PromotionAlternateKey, p.PromotionName, p.DiscountPct, p.PromotionType, p.PromotionCategory,
       p.StartDate, p.EndDate
FROM edw.DimPromotion p
WHERE p.PromotionKey = -1
   OR EXISTS (SELECT 1 FROM edw.FactSales fs WHERE fs.PromotionKey = p.PromotionKey AND fs.SalesChannel = N'Internet');
GO

CREATE OR ALTER VIEW dm_internet_sales.DimSalesReason AS
SELECT SalesReasonKey, SalesReasonAlternateKey, SalesReasonName, SalesReasonType
FROM edw.DimSalesReason;
GO

CREATE OR ALTER VIEW dm_internet_sales.DimShipMethod AS
SELECT ShipMethodKey, ShipMethodName FROM edw.DimShipMethod;
GO

CREATE OR ALTER VIEW dm_internet_sales.DimCurrency AS
SELECT CurrencyKey, CurrencyAlternateKey, CurrencyName FROM edw.DimCurrency;
GO


/*==============================================================================
    2. RESELLER SALES DATA MART  (dm_reseller_sales)
==============================================================================*/

CREATE OR ALTER VIEW dm_reseller_sales.FactResellerSales AS
SELECT
    SalesOrderLineKey, SalesOrderNumber, SalesOrderLineNumber,
    OrderDateKey, DueDateKey, ShipDateKey,
    ProductKey, ResellerKey, EmployeeKey, TerritoryKey, PromotionKey, ShipMethodKey, CurrencyKey,
    OrderQuantity, UnitPrice, ExtendedAmount, UnitPriceDiscountPct, DiscountAmount, SalesAmount,
    ProductStandardCost, TotalProductCost, GrossProfit, TaxAmount, FreightAmount
FROM edw.FactSales
WHERE SalesChannel = N'Reseller';
GO

CREATE OR ALTER VIEW dm_reseller_sales.FactSalesQuota AS
SELECT SalesQuotaKey, EmployeeKey, QuotaDateKey, SalesAmountQuota FROM edw.FactSalesQuota;
GO

CREATE OR ALTER VIEW dm_reseller_sales.DimDate AS SELECT * FROM edw.DimDate;
GO
CREATE OR ALTER VIEW dm_reseller_sales.DimProduct AS
SELECT ProductKey, ProductAlternateKey, ProductNumber, ProductName, Color, Size, StandardCost, ListPrice,
       ProductLine, Class, Style, ProductModelName, SubcategoryName, CategoryName
FROM edw.DimProduct;
GO
CREATE OR ALTER VIEW dm_reseller_sales.DimReseller AS SELECT * FROM edw.DimReseller;
GO
CREATE OR ALTER VIEW dm_reseller_sales.DimEmployee AS
SELECT EmployeeKey, EmployeeAlternateKey, ParentEmployeeKey, FullName, JobTitle, DepartmentName, SalesTerritoryKey, IsSalesPerson
FROM edw.DimEmployee
WHERE IsSalesPerson = 1 OR EmployeeKey = -1 OR JobTitle LIKE N'%Sales%';
GO
CREATE OR ALTER VIEW dm_reseller_sales.DimTerritory AS SELECT * FROM edw.DimTerritory;
GO
CREATE OR ALTER VIEW dm_reseller_sales.DimPromotion AS SELECT * FROM edw.DimPromotion;
GO


/*==============================================================================
    3. PURCHASING DATA MART  (dm_purchasing)
==============================================================================*/

CREATE OR ALTER VIEW dm_purchasing.FactPurchases AS SELECT * FROM edw.FactPurchases;
GO
CREATE OR ALTER VIEW dm_purchasing.DimDate AS SELECT * FROM edw.DimDate;
GO
CREATE OR ALTER VIEW dm_purchasing.DimProduct AS
SELECT ProductKey, ProductAlternateKey, ProductNumber, ProductName, Color, StandardCost, ListPrice,
       MakeFlag, SafetyStockLevel, ReorderPoint, SubcategoryName, CategoryName
FROM edw.DimProduct;
GO
CREATE OR ALTER VIEW dm_purchasing.DimVendor AS SELECT * FROM edw.DimVendor;
GO
CREATE OR ALTER VIEW dm_purchasing.DimShipMethod AS SELECT * FROM edw.DimShipMethod;
GO
CREATE OR ALTER VIEW dm_purchasing.DimEmployee AS
SELECT e.EmployeeKey, e.FullName, e.JobTitle, e.DepartmentName
FROM edw.DimEmployee e
WHERE e.EmployeeKey = -1 OR EXISTS (SELECT 1 FROM edw.FactPurchases f WHERE f.EmployeeKey = e.EmployeeKey);
GO


/*==============================================================================
    4. PRODUCTION DATA MART  (dm_production)
==============================================================================*/

CREATE OR ALTER VIEW dm_production.FactProductionWorkOrder AS SELECT * FROM edw.FactProductionWorkOrder;
GO
CREATE OR ALTER VIEW dm_production.DimDate AS SELECT * FROM edw.DimDate;
GO
CREATE OR ALTER VIEW dm_production.DimProduct AS
SELECT p.ProductKey, p.ProductAlternateKey, p.ProductNumber, p.ProductName, p.Color, p.StandardCost, p.DaysToManufacture,
       p.ProductLine, p.ProductModelName, p.SubcategoryName, p.CategoryName
FROM edw.DimProduct p
WHERE p.ProductKey = -1 OR EXISTS (SELECT 1 FROM edw.FactProductionWorkOrder f WHERE f.ProductKey = p.ProductKey);
GO
CREATE OR ALTER VIEW dm_production.DimScrapReason AS SELECT * FROM edw.DimScrapReason;
GO


/*==============================================================================
    5. INVENTORY DATA MART  (dm_inventory)
==============================================================================*/

CREATE OR ALTER VIEW dm_inventory.FactInventoryTransaction AS SELECT * FROM edw.FactInventoryTransaction;
GO
CREATE OR ALTER VIEW dm_inventory.FactInventorySnapshot AS SELECT * FROM edw.FactInventorySnapshot;
GO
CREATE OR ALTER VIEW dm_inventory.DimDate AS SELECT * FROM edw.DimDate;
GO
CREATE OR ALTER VIEW dm_inventory.DimProduct AS
SELECT ProductKey, ProductAlternateKey, ProductNumber, ProductName, Color, StandardCost, ListPrice,
       SafetyStockLevel, ReorderPoint, ProductLine, SubcategoryName, CategoryName
FROM edw.DimProduct;
GO
CREATE OR ALTER VIEW dm_inventory.DimLocation AS SELECT * FROM edw.DimLocation;
GO


/*==============================================================================
    6. VERIFY THE MARTS
==============================================================================*/

-- Internet Sales mart totals (compare with the dashboard)
SELECT COUNT(*) AS OrderLines, COUNT(DISTINCT SalesOrderNumber) AS Orders, COUNT(DISTINCT CustomerKey) AS Customers,
       SUM(OrderQuantity) AS Quantity, SUM(SalesAmount) AS SalesAmount, SUM(GrossProfit) AS GrossProfit
FROM dm_internet_sales.FactInternetSales;

-- Every mart object and the rows it exposes
SELECT s.name AS MartSchema, v.name AS ViewName
FROM sys.views v JOIN sys.schemas s ON s.schema_id = v.schema_id
WHERE s.name LIKE N'dm[_]%'
ORDER BY s.name, v.name;

PRINT 'Script 06 completed: data marts created.';
GO
