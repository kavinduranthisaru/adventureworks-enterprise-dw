USE AdventureWorks_DW;
GO
SET NOCOUNT ON;
GO


/*==============================================================================
    1. STAGING TABLES
==============================================================================*/

-- 1.1 File sources (CSV columns staged as NVARCHAR so dirty values never break the load)
DROP TABLE IF EXISTS stg.Product;
CREATE TABLE stg.Product
(
    ProductID NVARCHAR(50), Name NVARCHAR(255), ProductNumber NVARCHAR(50), MakeFlag NVARCHAR(50),
    FinishedGoodsFlag NVARCHAR(50), Color NVARCHAR(50), SafetyStockLevel NVARCHAR(50), ReorderPoint NVARCHAR(50),
    StandardCost NVARCHAR(50), ListPrice NVARCHAR(50), Size NVARCHAR(50), SizeUnitMeasureCode NVARCHAR(50),
    WeightUnitMeasureCode NVARCHAR(50), Weight NVARCHAR(50), DaysToManufacture NVARCHAR(50), ProductLine NVARCHAR(50),
    Class NVARCHAR(50), Style NVARCHAR(50), ProductSubcategoryID NVARCHAR(50), ProductModelID NVARCHAR(50),
    SellStartDate NVARCHAR(100), SellEndDate NVARCHAR(100), DiscontinuedDate NVARCHAR(100),
    rowguid NVARCHAR(100), ModifiedDate NVARCHAR(100)
);

DROP TABLE IF EXISTS stg.ProductSubcategory;
CREATE TABLE stg.ProductSubcategory
(
    ProductSubcategoryID NVARCHAR(50), ProductCategoryID NVARCHAR(50), Name NVARCHAR(255),
    rowguid NVARCHAR(100), ModifiedDate NVARCHAR(100)
);

DROP TABLE IF EXISTS stg.ProductCategory;
CREATE TABLE stg.ProductCategory
(
    ProductCategoryID NVARCHAR(50), Name NVARCHAR(255), rowguid NVARCHAR(100), ModifiedDate NVARCHAR(100)
);

DROP TABLE IF EXISTS stg.SalesTerritory;
CREATE TABLE stg.SalesTerritory
(
    TerritoryID INT, RegionName NVARCHAR(50), CountryRegionCode NVARCHAR(3), TerritoryGroup NVARCHAR(50)
);

DROP TABLE IF EXISTS stg.SpecialOffer;
CREATE TABLE stg.SpecialOffer
(
    SpecialOfferID INT, Description NVARCHAR(255), DiscountPct NVARCHAR(50), Type NVARCHAR(50),
    Category NVARCHAR(50), StartDate NVARCHAR(50), EndDate NVARCHAR(50)
);

-- 1.2 Relational sources: Sales
DROP TABLE IF EXISTS stg.SalesOrderHeader;
CREATE TABLE stg.SalesOrderHeader
(
    SalesOrderID INT, RevisionNumber TINYINT, OrderDate DATETIME, DueDate DATETIME, ShipDate DATETIME,
    Status TINYINT, OnlineOrderFlag BIT, SalesOrderNumber NVARCHAR(25), PurchaseOrderNumber NVARCHAR(25),
    AccountNumber NVARCHAR(15), CustomerID INT, SalesPersonID INT, TerritoryID INT, ShipMethodID INT,
    CurrencyRateID INT, SubTotal DECIMAL(19,4), TaxAmt DECIMAL(19,4), Freight DECIMAL(19,4), TotalDue DECIMAL(19,4)
);

DROP TABLE IF EXISTS stg.SalesOrderDetail;
CREATE TABLE stg.SalesOrderDetail
(
    SalesOrderID INT, SalesOrderDetailID INT, CarrierTrackingNumber NVARCHAR(25), OrderQty SMALLINT,
    ProductID INT, SpecialOfferID INT, UnitPrice DECIMAL(19,4), UnitPriceDiscount DECIMAL(19,4), LineTotal DECIMAL(19,6)
);

DROP TABLE IF EXISTS stg.SalesOrderHeaderSalesReason;
CREATE TABLE stg.SalesOrderHeaderSalesReason ( SalesOrderID INT, SalesReasonID INT );

DROP TABLE IF EXISTS stg.SalesReason;
CREATE TABLE stg.SalesReason ( SalesReasonID INT, Name NVARCHAR(50), ReasonType NVARCHAR(50) );

DROP TABLE IF EXISTS stg.Customer;
CREATE TABLE stg.Customer ( CustomerID INT, PersonID INT, StoreID INT, TerritoryID INT, AccountNumber NVARCHAR(10) );

DROP TABLE IF EXISTS stg.Store;
CREATE TABLE stg.Store ( BusinessEntityID INT, Name NVARCHAR(50), SalesPersonID INT, Demographics NVARCHAR(MAX) );

DROP TABLE IF EXISTS stg.SalesPerson;
CREATE TABLE stg.SalesPerson
(
    BusinessEntityID INT, TerritoryID INT, SalesQuota DECIMAL(19,4), Bonus DECIMAL(19,4), CommissionPct DECIMAL(10,4)
);

DROP TABLE IF EXISTS stg.SalesPersonQuotaHistory;
CREATE TABLE stg.SalesPersonQuotaHistory ( BusinessEntityID INT, QuotaDate DATETIME, SalesQuota DECIMAL(19,4) );

DROP TABLE IF EXISTS stg.Currency;
CREATE TABLE stg.Currency ( CurrencyCode NCHAR(3), Name NVARCHAR(50) );

DROP TABLE IF EXISTS stg.CurrencyRate;
CREATE TABLE stg.CurrencyRate
(
    CurrencyRateID INT, CurrencyRateDate DATETIME, FromCurrencyCode NCHAR(3), ToCurrencyCode NCHAR(3),
    AverageRate DECIMAL(19,4), EndOfDayRate DECIMAL(19,4)
);

-- 1.3 Relational sources
DROP TABLE IF EXISTS stg.Person;
CREATE TABLE stg.Person
(
    BusinessEntityID INT, PersonType NCHAR(2), Title NVARCHAR(8), FirstName NVARCHAR(50), MiddleName NVARCHAR(50),
    LastName NVARCHAR(50), Suffix NVARCHAR(10), EmailPromotion INT, Demographics NVARCHAR(MAX)
);

DROP TABLE IF EXISTS stg.BusinessEntityAddress;
CREATE TABLE stg.BusinessEntityAddress ( BusinessEntityID INT, AddressID INT, AddressTypeID INT );

DROP TABLE IF EXISTS stg.Address;
CREATE TABLE stg.Address
(
    AddressID INT, AddressLine1 NVARCHAR(60), City NVARCHAR(30), StateProvinceID INT, PostalCode NVARCHAR(15)
);

DROP TABLE IF EXISTS stg.StateProvince;
CREATE TABLE stg.StateProvince
(
    StateProvinceID INT, StateProvinceCode NCHAR(3), CountryRegionCode NVARCHAR(3), Name NVARCHAR(50), TerritoryID INT
);

DROP TABLE IF EXISTS stg.CountryRegion;
CREATE TABLE stg.CountryRegion ( CountryRegionCode NVARCHAR(3), Name NVARCHAR(50) );

-- 1.4 Relational sources
DROP TABLE IF EXISTS stg.Employee;
CREATE TABLE stg.Employee
(
    BusinessEntityID INT, LoginID NVARCHAR(256), OrganizationNode NVARCHAR(100), ParentOrganizationNode NVARCHAR(100),
    OrganizationLevel SMALLINT, JobTitle NVARCHAR(50), BirthDate DATE, MaritalStatus NCHAR(1), Gender NCHAR(1),
    HireDate DATE, SalariedFlag BIT, VacationHours SMALLINT, SickLeaveHours SMALLINT, CurrentFlag BIT
);

DROP TABLE IF EXISTS stg.EmployeeDepartmentHistory;
CREATE TABLE stg.EmployeeDepartmentHistory
(
    BusinessEntityID INT, DepartmentID SMALLINT, ShiftID TINYINT, StartDate DATE, EndDate DATE
);

DROP TABLE IF EXISTS stg.Department;
CREATE TABLE stg.Department ( DepartmentID SMALLINT, Name NVARCHAR(50), GroupName NVARCHAR(50) );

DROP TABLE IF EXISTS stg.Shift;
CREATE TABLE stg.Shift ( ShiftID TINYINT, Name NVARCHAR(50) );

-- 1.5 Relational sources
DROP TABLE IF EXISTS stg.Vendor;
CREATE TABLE stg.Vendor
(
    BusinessEntityID INT, AccountNumber NVARCHAR(15), Name NVARCHAR(50), CreditRating TINYINT,
    PreferredVendorStatus BIT, ActiveFlag BIT
);

DROP TABLE IF EXISTS stg.PurchaseOrderHeader;
CREATE TABLE stg.PurchaseOrderHeader
(
    PurchaseOrderID INT, RevisionNumber TINYINT, Status TINYINT, EmployeeID INT, VendorID INT, ShipMethodID INT,
    OrderDate DATETIME, ShipDate DATETIME, SubTotal DECIMAL(19,4), TaxAmt DECIMAL(19,4), Freight DECIMAL(19,4), TotalDue DECIMAL(19,4)
);

DROP TABLE IF EXISTS stg.PurchaseOrderDetail;
CREATE TABLE stg.PurchaseOrderDetail
(
    PurchaseOrderID INT, PurchaseOrderDetailID INT, DueDate DATETIME, OrderQty SMALLINT, ProductID INT,
    UnitPrice DECIMAL(19,4), LineTotal DECIMAL(19,4), ReceivedQty DECIMAL(8,2), RejectedQty DECIMAL(8,2), StockedQty DECIMAL(9,2)
);

DROP TABLE IF EXISTS stg.ShipMethod;
CREATE TABLE stg.ShipMethod ( ShipMethodID INT, Name NVARCHAR(50), ShipBase DECIMAL(19,4), ShipRate DECIMAL(19,4) );

-- 1.6 Relational sources
DROP TABLE IF EXISTS stg.ProductModel;
CREATE TABLE stg.ProductModel ( ProductModelID INT, Name NVARCHAR(50) );

DROP TABLE IF EXISTS stg.ProductCostHistory;
CREATE TABLE stg.ProductCostHistory ( ProductID INT, StartDate DATETIME, EndDate DATETIME, StandardCost DECIMAL(19,4) );

DROP TABLE IF EXISTS stg.WorkOrder;
CREATE TABLE stg.WorkOrder
(
    WorkOrderID INT, ProductID INT, OrderQty INT, StockedQty INT, ScrappedQty SMALLINT,
    StartDate DATETIME, EndDate DATETIME, DueDate DATETIME, ScrapReasonID SMALLINT
);

DROP TABLE IF EXISTS stg.WorkOrderRouting;
CREATE TABLE stg.WorkOrderRouting
(
    WorkOrderID INT, ProductID INT, OperationSequence SMALLINT, LocationID SMALLINT,
    ActualResourceHrs DECIMAL(9,4), PlannedCost DECIMAL(19,4), ActualCost DECIMAL(19,4)
);

DROP TABLE IF EXISTS stg.ScrapReason;
CREATE TABLE stg.ScrapReason ( ScrapReasonID SMALLINT, Name NVARCHAR(50) );

DROP TABLE IF EXISTS stg.Location;
CREATE TABLE stg.Location ( LocationID SMALLINT, Name NVARCHAR(50), CostRate DECIMAL(10,4), Availability DECIMAL(8,2) );

DROP TABLE IF EXISTS stg.ProductInventory;
CREATE TABLE stg.ProductInventory
(
    ProductID INT, LocationID SMALLINT, Shelf NVARCHAR(10), Bin TINYINT, Quantity SMALLINT, ModifiedDate DATETIME
);

DROP TABLE IF EXISTS stg.TransactionHistory;
CREATE TABLE stg.TransactionHistory
(
    SourceTable NVARCHAR(10), TransactionID INT, ProductID INT, ReferenceOrderID INT, ReferenceOrderLineID INT,
    TransactionDate DATETIME, TransactionType NCHAR(1), Quantity INT, ActualCost DECIMAL(19,4)
);
GO


/*==============================================================================
    2. EXTRACT FILE SOURCES (CSV, JSON, XML)
==============================================================================*/

DECLARE @Path NVARCHAR(400) = (SELECT ConfigValue FROM etl.PipelineConfig WHERE ConfigKey = N'SourceFilePath');
DECLARE @sql NVARCHAR(MAX), @t DATETIME2(0), @rc INT;

-- 2.1 CSV: product catalogue (quoted fields contain commas, UTF-8 with BOM)
SET @t = SYSDATETIME();
SET @sql = N'BULK INSERT stg.Product FROM ''' + @Path + N'Product.csv''
             WITH (FORMAT = ''CSV'', FIRSTROW = 2, FIELDQUOTE = ''"'', FIELDTERMINATOR = '','',
                   ROWTERMINATOR = ''0x0d0a'', CODEPAGE = ''65001'', TABLOCK);';
EXEC sys.sp_executesql @sql;
SET @rc = (SELECT COUNT(*) FROM stg.Product);
EXEC etl.usp_LogStep N'Extract CSV', N'stg.Product', @rc, @t;

SET @t = SYSDATETIME();
SET @sql = N'BULK INSERT stg.ProductSubcategory FROM ''' + @Path + N'ProductSubCategory.csv''
             WITH (FORMAT = ''CSV'', FIRSTROW = 2, FIELDQUOTE = ''"'', FIELDTERMINATOR = '','',
                   ROWTERMINATOR = ''0x0d0a'', CODEPAGE = ''65001'', TABLOCK);';
EXEC sys.sp_executesql @sql;
SET @rc = (SELECT COUNT(*) FROM stg.ProductSubcategory);
EXEC etl.usp_LogStep N'Extract CSV', N'stg.ProductSubcategory', @rc, @t;

SET @t = SYSDATETIME();
SET @sql = N'BULK INSERT stg.ProductCategory FROM ''' + @Path + N'ProductCategory.csv''
             WITH (FORMAT = ''CSV'', FIRSTROW = 2, FIELDQUOTE = ''"'', FIELDTERMINATOR = '','',
                   ROWTERMINATOR = ''0x0d0a'', CODEPAGE = ''65001'', TABLOCK);';
EXEC sys.sp_executesql @sql;
SET @rc = (SELECT COUNT(*) FROM stg.ProductCategory);
EXEC etl.usp_LogStep N'Extract CSV', N'stg.ProductCategory', @rc, @t;

-- 2.2 JSON: territory feed (the leading UTF-8 byte-order mark is skipped before parsing)
SET @t = SYSDATETIME();
SET @sql = N'INSERT INTO stg.SalesTerritory (TerritoryID, RegionName, CountryRegionCode, TerritoryGroup)
             SELECT j.TerritoryID, j.RegionName, j.CountryRegionCode, j.TerritoryGroup
             FROM OPENROWSET(BULK ''' + @Path + N'SalesTerritory.json'', SINGLE_CLOB) AS src
             CROSS APPLY OPENJSON(SUBSTRING(src.BulkColumn, CHARINDEX(''{'', src.BulkColumn), LEN(src.BulkColumn)), ''$.Territories'')
                  WITH (TerritoryID INT, RegionName NVARCHAR(50), CountryRegionCode NVARCHAR(3), TerritoryGroup NVARCHAR(50)) AS j;';
EXEC sys.sp_executesql @sql;
SET @rc = (SELECT COUNT(*) FROM stg.SalesTerritory);
EXEC etl.usp_LogStep N'Extract JSON', N'stg.SalesTerritory', @rc, @t;

-- 2.3 XML: promotions
SET @t = SYSDATETIME();
SET @sql = N'INSERT INTO stg.SpecialOffer (SpecialOfferID, Description, DiscountPct, Type, Category, StartDate, EndDate)
             SELECT T.c.value(''(SpecialOfferID)[1]'', ''INT''),
                    T.c.value(''(Description)[1]'',    ''NVARCHAR(255)''),
                    T.c.value(''(DiscountPct)[1]'',    ''NVARCHAR(50)''),
                    T.c.value(''(Type)[1]'',           ''NVARCHAR(50)''),
                    T.c.value(''(Category)[1]'',       ''NVARCHAR(50)''),
                    T.c.value(''(StartDate)[1]'',      ''NVARCHAR(50)''),
                    T.c.value(''(EndDate)[1]'',        ''NVARCHAR(50)'')
             FROM OPENROWSET(BULK ''' + @Path + N'Sales.SalesOffers.xml'', SINGLE_BLOB) AS src
             CROSS APPLY (SELECT CAST(src.BulkColumn AS XML) AS Doc) AS d
             CROSS APPLY d.Doc.nodes(''/Promotions/Promotion'') AS T(c);';
EXEC sys.sp_executesql @sql;
SET @rc = (SELECT COUNT(*) FROM stg.SpecialOffer);
EXEC etl.usp_LogStep N'Extract XML', N'stg.SpecialOffer', @rc, @t;
GO


/*==============================================================================
    3. EXTRACT RELATIONAL SOURCE 
==============================================================================*/

DECLARE @t DATETIME2(0), @rc INT;

-- 3.1 Sales
SET @t = SYSDATETIME();
INSERT INTO stg.SalesOrderHeader
SELECT SalesOrderID, RevisionNumber, OrderDate, DueDate, ShipDate, Status, OnlineOrderFlag, SalesOrderNumber,
       PurchaseOrderNumber, AccountNumber, CustomerID, SalesPersonID, TerritoryID, ShipMethodID, CurrencyRateID,
       SubTotal, TaxAmt, Freight, TotalDue
FROM AdventureWorks2022.Sales.SalesOrderHeader;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.SalesOrderHeader', @rc, @t;

SET @t = SYSDATETIME();
INSERT INTO stg.SalesOrderDetail
SELECT SalesOrderID, SalesOrderDetailID, CarrierTrackingNumber, OrderQty, ProductID, SpecialOfferID,
       UnitPrice, UnitPriceDiscount, LineTotal
FROM AdventureWorks2022.Sales.SalesOrderDetail;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.SalesOrderDetail', @rc, @t;

SET @t = SYSDATETIME();
INSERT INTO stg.SalesOrderHeaderSalesReason SELECT SalesOrderID, SalesReasonID FROM AdventureWorks2022.Sales.SalesOrderHeaderSalesReason;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.SalesOrderHeaderSalesReason', @rc, @t;

SET @t = SYSDATETIME();
INSERT INTO stg.SalesReason SELECT SalesReasonID, Name, ReasonType FROM AdventureWorks2022.Sales.SalesReason;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.SalesReason', @rc, @t;

SET @t = SYSDATETIME();
INSERT INTO stg.Customer SELECT CustomerID, PersonID, StoreID, TerritoryID, AccountNumber FROM AdventureWorks2022.Sales.Customer;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.Customer', @rc, @t;

SET @t = SYSDATETIME();
INSERT INTO stg.Store SELECT BusinessEntityID, Name, SalesPersonID, CAST(Demographics AS NVARCHAR(MAX)) FROM AdventureWorks2022.Sales.Store;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.Store', @rc, @t;

SET @t = SYSDATETIME();
INSERT INTO stg.SalesPerson SELECT BusinessEntityID, TerritoryID, SalesQuota, Bonus, CommissionPct FROM AdventureWorks2022.Sales.SalesPerson;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.SalesPerson', @rc, @t;

SET @t = SYSDATETIME();
INSERT INTO stg.SalesPersonQuotaHistory SELECT BusinessEntityID, QuotaDate, SalesQuota FROM AdventureWorks2022.Sales.SalesPersonQuotaHistory;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.SalesPersonQuotaHistory', @rc, @t;

SET @t = SYSDATETIME();
INSERT INTO stg.Currency SELECT CurrencyCode, Name FROM AdventureWorks2022.Sales.Currency;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.Currency', @rc, @t;

SET @t = SYSDATETIME();
INSERT INTO stg.CurrencyRate
SELECT CurrencyRateID, CurrencyRateDate, FromCurrencyCode, ToCurrencyCode, AverageRate, EndOfDayRate
FROM AdventureWorks2022.Sales.CurrencyRate;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.CurrencyRate', @rc, @t;

-- 3.2 Person and geography
SET @t = SYSDATETIME();
INSERT INTO stg.Person
SELECT BusinessEntityID, PersonType, Title, FirstName, MiddleName, LastName, Suffix, EmailPromotion,
       CAST(Demographics AS NVARCHAR(MAX))
FROM AdventureWorks2022.Person.Person;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.Person', @rc, @t;

SET @t = SYSDATETIME();
INSERT INTO stg.BusinessEntityAddress SELECT BusinessEntityID, AddressID, AddressTypeID FROM AdventureWorks2022.Person.BusinessEntityAddress;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.BusinessEntityAddress', @rc, @t;

SET @t = SYSDATETIME();
INSERT INTO stg.Address SELECT AddressID, AddressLine1, City, StateProvinceID, PostalCode FROM AdventureWorks2022.Person.Address;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.Address', @rc, @t;

SET @t = SYSDATETIME();
INSERT INTO stg.StateProvince
SELECT StateProvinceID, StateProvinceCode, CountryRegionCode, Name, TerritoryID FROM AdventureWorks2022.Person.StateProvince;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.StateProvince', @rc, @t;

SET @t = SYSDATETIME();
INSERT INTO stg.CountryRegion SELECT CountryRegionCode, Name FROM AdventureWorks2022.Person.CountryRegion;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.CountryRegion', @rc, @t;

-- 3.3 Human resources
SET @t = SYSDATETIME();
INSERT INTO stg.Employee
SELECT BusinessEntityID, LoginID,
       ISNULL(OrganizationNode, hierarchyid::GetRoot()).ToString(),                  -- CEO = root '/'
       ISNULL(OrganizationNode, hierarchyid::GetRoot()).GetAncestor(1).ToString(),
       ISNULL(OrganizationLevel, 0), JobTitle, BirthDate, MaritalStatus, Gender, HireDate, SalariedFlag,
       VacationHours, SickLeaveHours, CurrentFlag
FROM AdventureWorks2022.HumanResources.Employee;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.Employee', @rc, @t;

SET @t = SYSDATETIME();
INSERT INTO stg.EmployeeDepartmentHistory
SELECT BusinessEntityID, DepartmentID, ShiftID, StartDate, EndDate FROM AdventureWorks2022.HumanResources.EmployeeDepartmentHistory;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.EmployeeDepartmentHistory', @rc, @t;

SET @t = SYSDATETIME();
INSERT INTO stg.Department SELECT DepartmentID, Name, GroupName FROM AdventureWorks2022.HumanResources.Department;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.Department', @rc, @t;

SET @t = SYSDATETIME();
INSERT INTO stg.Shift SELECT ShiftID, Name FROM AdventureWorks2022.HumanResources.Shift;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.Shift', @rc, @t;

-- 3.4 Purchasing
SET @t = SYSDATETIME();
INSERT INTO stg.Vendor
SELECT BusinessEntityID, AccountNumber, Name, CreditRating, PreferredVendorStatus, ActiveFlag FROM AdventureWorks2022.Purchasing.Vendor;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.Vendor', @rc, @t;

SET @t = SYSDATETIME();
INSERT INTO stg.PurchaseOrderHeader
SELECT PurchaseOrderID, RevisionNumber, Status, EmployeeID, VendorID, ShipMethodID, OrderDate, ShipDate,
       SubTotal, TaxAmt, Freight, TotalDue
FROM AdventureWorks2022.Purchasing.PurchaseOrderHeader;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.PurchaseOrderHeader', @rc, @t;

SET @t = SYSDATETIME();
INSERT INTO stg.PurchaseOrderDetail
SELECT PurchaseOrderID, PurchaseOrderDetailID, DueDate, OrderQty, ProductID, UnitPrice, LineTotal,
       ReceivedQty, RejectedQty, StockedQty
FROM AdventureWorks2022.Purchasing.PurchaseOrderDetail;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.PurchaseOrderDetail', @rc, @t;

SET @t = SYSDATETIME();
INSERT INTO stg.ShipMethod SELECT ShipMethodID, Name, ShipBase, ShipRate FROM AdventureWorks2022.Purchasing.ShipMethod;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.ShipMethod', @rc, @t;

-- 3.5 Production and inventory
SET @t = SYSDATETIME();
INSERT INTO stg.ProductModel SELECT ProductModelID, Name FROM AdventureWorks2022.Production.ProductModel;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.ProductModel', @rc, @t;

SET @t = SYSDATETIME();
INSERT INTO stg.ProductCostHistory SELECT ProductID, StartDate, EndDate, StandardCost FROM AdventureWorks2022.Production.ProductCostHistory;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.ProductCostHistory', @rc, @t;

SET @t = SYSDATETIME();
INSERT INTO stg.WorkOrder
SELECT WorkOrderID, ProductID, OrderQty, StockedQty, ScrappedQty, StartDate, EndDate, DueDate, ScrapReasonID
FROM AdventureWorks2022.Production.WorkOrder;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.WorkOrder', @rc, @t;

SET @t = SYSDATETIME();
INSERT INTO stg.WorkOrderRouting
SELECT WorkOrderID, ProductID, OperationSequence, LocationID, ActualResourceHrs, PlannedCost, ActualCost
FROM AdventureWorks2022.Production.WorkOrderRouting;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.WorkOrderRouting', @rc, @t;

SET @t = SYSDATETIME();
INSERT INTO stg.ScrapReason SELECT ScrapReasonID, Name FROM AdventureWorks2022.Production.ScrapReason;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.ScrapReason', @rc, @t;

SET @t = SYSDATETIME();
INSERT INTO stg.Location SELECT LocationID, Name, CostRate, Availability FROM AdventureWorks2022.Production.Location;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.Location', @rc, @t;

SET @t = SYSDATETIME();
INSERT INTO stg.ProductInventory SELECT ProductID, LocationID, Shelf, Bin, Quantity, ModifiedDate FROM AdventureWorks2022.Production.ProductInventory;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.ProductInventory', @rc, @t;

SET @t = SYSDATETIME();
INSERT INTO stg.TransactionHistory
SELECT N'Current', TransactionID, ProductID, ReferenceOrderID, ReferenceOrderLineID, TransactionDate,
       TransactionType, Quantity, ActualCost
FROM AdventureWorks2022.Production.TransactionHistory
UNION ALL
SELECT N'Archive', TransactionID, ProductID, ReferenceOrderID, ReferenceOrderLineID, TransactionDate,
       TransactionType, Quantity, ActualCost
FROM AdventureWorks2022.Production.TransactionHistoryArchive;
SET @rc = @@ROWCOUNT; EXEC etl.usp_LogStep N'Extract DB', N'stg.TransactionHistory', @rc, @t;
GO


/*==============================================================================
    4. EXTRACTION SUMMARY
==============================================================================*/

SELECT TargetTable, RowsProcessed, ProcessName, ExecutionEndTime
FROM etl.ExecutionLog
WHERE ProcessName LIKE N'Extract%'
ORDER BY LogID;

PRINT 'Script 03 completed: all sources extracted into stg.';
GO
