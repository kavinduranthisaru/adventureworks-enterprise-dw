/*==============================================================================
    1. DATABASE PROVISIONING
==============================================================================*/

CREATE DATABASE AdventureWorks_DW;
GO

ALTER DATABASE AdventureWorks_DW SET RECOVERY SIMPLE;   -- DW is reloadable; keeps the log small
GO

USE AdventureWorks_DW;
GO


/*==============================================================================
    2. SCHEMA SEPARATION
==============================================================================*/

CREATE SCHEMA stg;                 -- Staging area: raw landing of every source
GO
CREATE SCHEMA edw;                 -- Enterprise Data Warehouse: conformed dimensions + all facts
GO
CREATE SCHEMA etl;                 -- ETL control: configuration, logging, data quality results
GO
CREATE SCHEMA dm_internet_sales;   -- Data mart: Internet Sales (e-commerce department)
GO
CREATE SCHEMA dm_reseller_sales;   -- Data mart: Reseller Sales and sales-force performance
GO
CREATE SCHEMA dm_purchasing;       -- Data mart: Purchasing / procurement
GO
CREATE SCHEMA dm_production;       -- Data mart: Manufacturing / production
GO
CREATE SCHEMA dm_inventory;        -- Data mart: Inventory and stock movement
GO


/*==============================================================================
    3. ETL CONTROL OBJECTS
==============================================================================*/

-- 3.1 Pipeline configuration (no hard-coded file paths inside the ETL scripts)
CREATE TABLE etl.PipelineConfig
(
    ConfigKey    NVARCHAR(100) NOT NULL CONSTRAINT PK_PipelineConfig PRIMARY KEY,
    ConfigValue  NVARCHAR(400) NOT NULL,
    Description  NVARCHAR(400) NULL
);

INSERT INTO etl.PipelineConfig (ConfigKey, ConfigValue, Description)
VALUES
(N'SourceFilePath',
 N'C:\Users\VICTUS\Downloads\DWBI Assignment\DWBI_Project_Files\',
 N'Folder that holds the CSV, JSON and XML source files. Must end with a backslash. If access is denied, copy the files to C:\DWBI_Source\ and update this value.');
GO

-- 3.2 Execution log (one row per ETL step)
CREATE TABLE etl.ExecutionLog
(
    LogID               INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ExecutionLog PRIMARY KEY,
    ProcessName         NVARCHAR(100) NOT NULL,
    TargetTable         NVARCHAR(128) NOT NULL,
    RowsProcessed       INT NULL,
    ExecutionStartTime  DATETIME2(0) NOT NULL CONSTRAINT DF_ExecutionLog_Start DEFAULT SYSDATETIME(),
    ExecutionEndTime    DATETIME2(0) NULL,
    Status              NVARCHAR(20) NOT NULL,
    Message             NVARCHAR(4000) NULL
);
GO

-- 3.3 Data quality results (written by Script 07)
CREATE TABLE etl.DataQualityResult
(
    CheckID      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DataQualityResult PRIMARY KEY,
    CheckTime    DATETIME2(0) NOT NULL CONSTRAINT DF_DataQualityResult_Time DEFAULT SYSDATETIME(),
    CheckGroup   NVARCHAR(50)  NOT NULL,      -- Completeness / Uniqueness / Integrity / Reconciliation
    TableName    NVARCHAR(128) NOT NULL,
    CheckName    NVARCHAR(200) NOT NULL,
    ExpectedValue DECIMAL(19,4) NULL,
    ActualValue   DECIMAL(19,4) NULL,
    -- PASS when equal; money totals may differ by allocation rounding (tolerance 0.0001%)
    Status       AS (CASE WHEN ABS(ISNULL(ExpectedValue,0) - ISNULL(ActualValue,0))
                               <= CASE WHEN ABS(ISNULL(ExpectedValue,0)) > 100000
                                       THEN ABS(ExpectedValue) * 0.000001 ELSE 0.5 END
                          THEN N'PASS' ELSE N'FAIL' END)
);
GO

-- 3.4 Logging helper
CREATE OR ALTER PROCEDURE etl.usp_LogStep
    @ProcessName NVARCHAR(100),
    @TargetTable NVARCHAR(128),
    @RowsProcessed INT,
    @StartTime DATETIME2(0),
    @Status NVARCHAR(20) = N'Success',
    @Message NVARCHAR(4000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO etl.ExecutionLog (ProcessName, TargetTable, RowsProcessed, ExecutionStartTime, ExecutionEndTime, Status, Message)
    VALUES (@ProcessName, @TargetTable, @RowsProcessed, @StartTime, SYSDATETIME(), @Status, @Message);
END;
GO

-- 3.5 Reusable cleansing function: trims text and turns '', 'NULL' into real NULLs
CREATE OR ALTER FUNCTION etl.fn_CleanText (@Value NVARCHAR(4000))
RETURNS NVARCHAR(4000)
WITH SCHEMABINDING
AS
BEGIN
    RETURN NULLIF(NULLIF(LTRIM(RTRIM(@Value)), N''), N'NULL');
END;
GO


/*==============================================================================
    4. EDW CONFORMED DIMENSIONS
==============================================================================*/

-- 4.1 Date (role-playing: order, due, ship, start, end, transaction, quota...)
CREATE TABLE edw.DimDate
(
    DateKey               INT          NOT NULL CONSTRAINT PK_DimDate PRIMARY KEY,   -- YYYYMMDD, -1 = Unknown
    FullDate              DATE         NOT NULL,
    DayNumberOfWeek       TINYINT      NOT NULL,      -- 1 = Monday
    EnglishDayNameOfWeek  NVARCHAR(10) NOT NULL,
    DayNumberOfMonth      TINYINT      NOT NULL,
    DayNumberOfYear       SMALLINT     NOT NULL,
    WeekNumberOfYear      TINYINT      NOT NULL,
    EnglishMonthName      NVARCHAR(10) NOT NULL,
    MonthNumberOfYear     TINYINT      NOT NULL,
    CalendarQuarter       TINYINT      NOT NULL,
    CalendarSemester      TINYINT      NOT NULL,
    CalendarYear          SMALLINT     NOT NULL,
    YearMonthKey          INT          NOT NULL,      -- YYYYMM (sort key)
    MonthYearLabel        NVARCHAR(10) NOT NULL,      -- e.g. Jan 2013
    QuarterLabel          NVARCHAR(10) NOT NULL,      -- e.g. 2013 Q1
    FiscalQuarter         TINYINT      NOT NULL,      -- AdventureWorks fiscal year starts 1 July
    FiscalYear            SMALLINT     NOT NULL,
    IsWeekend             BIT          NOT NULL,
    CONSTRAINT UX_DimDate_FullDate UNIQUE (FullDate)
);

-- 4.2 Product (source: CSV files + ProductModel from the OLTP database)
CREATE TABLE edw.DimProduct
(
    ProductKey            INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimProduct PRIMARY KEY,
    ProductAlternateKey   INT           NOT NULL,
    ProductNumber         NVARCHAR(25)  NULL,
    ProductName           NVARCHAR(50)  NOT NULL,
    Color                 NVARCHAR(20)  NOT NULL,
    Size                  NVARCHAR(10)  NULL,
    SizeUnitMeasureCode   NVARCHAR(3)   NULL,
    Weight                DECIMAL(8,2)  NULL,
    WeightUnitMeasureCode NVARCHAR(3)   NULL,
    StandardCost          DECIMAL(19,4) NOT NULL,
    ListPrice             DECIMAL(19,4) NOT NULL,
    ProductLine           NVARCHAR(20)  NOT NULL,
    Class                 NVARCHAR(20)  NOT NULL,
    Style                 NVARCHAR(20)  NOT NULL,
    DaysToManufacture     INT           NULL,
    SafetyStockLevel      SMALLINT      NULL,
    ReorderPoint          SMALLINT      NULL,
    MakeFlag              BIT           NULL,
    FinishedGoodsFlag     BIT           NULL,
    ProductModelName      NVARCHAR(50)  NOT NULL,
    SubcategoryName       NVARCHAR(50)  NOT NULL,
    CategoryName          NVARCHAR(50)  NOT NULL,
    ETLLoadDate           DATETIME2(0)  NOT NULL CONSTRAINT DF_DimProduct_Load DEFAULT SYSDATETIME(),
    ETLUpdateDate         DATETIME2(0)  NULL,
    CONSTRAINT UX_DimProduct_AlternateKey UNIQUE (ProductAlternateKey)
);

-- 4.3 Customer (individual internet customers)
CREATE TABLE edw.DimCustomer
(
    CustomerKey           INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimCustomer PRIMARY KEY,
    CustomerAlternateKey  INT           NOT NULL,      -- Sales.Customer.CustomerID
    AccountNumber         NVARCHAR(10)  NULL,
    Title                 NVARCHAR(8)   NULL,
    FirstName             NVARCHAR(50)  NOT NULL,
    MiddleName            NVARCHAR(50)  NULL,
    LastName              NVARCHAR(50)  NOT NULL,
    FullName              NVARCHAR(160) NOT NULL,
    BirthDate             DATE          NULL,
    AgeGroup              NVARCHAR(20)  NOT NULL,
    Gender                NVARCHAR(10)  NOT NULL,
    MaritalStatus         NVARCHAR(10)  NOT NULL,
    YearlyIncome          NVARCHAR(30)  NOT NULL,
    TotalChildren         TINYINT       NULL,
    NumberChildrenAtHome  TINYINT       NULL,
    Education             NVARCHAR(40)  NOT NULL,
    Occupation            NVARCHAR(40)  NOT NULL,
    HomeOwnerFlag         BIT           NULL,
    NumberCarsOwned       TINYINT       NULL,
    CommuteDistance       NVARCHAR(20)  NOT NULL,
    DateFirstPurchase     DATE          NULL,
    EmailPromotion        TINYINT       NOT NULL,
    EmailPromotionDesc    NVARCHAR(40)  NOT NULL,
    City                  NVARCHAR(30)  NOT NULL,
    StateProvinceName     NVARCHAR(50)  NOT NULL,
    PostalCode            NVARCHAR(15)  NULL,
    CountryRegionCode     NVARCHAR(3)   NOT NULL,
    CountryRegionName     NVARCHAR(50)  NOT NULL,
    ETLLoadDate           DATETIME2(0)  NOT NULL CONSTRAINT DF_DimCustomer_Load DEFAULT SYSDATETIME(),
    ETLUpdateDate         DATETIME2(0)  NULL,
    CONSTRAINT UX_DimCustomer_AlternateKey UNIQUE (CustomerAlternateKey)
);

-- 4.4 Reseller (stores that buy through the reseller channel)
CREATE TABLE edw.DimReseller
(
    ResellerKey           INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimReseller PRIMARY KEY,
    ResellerAlternateKey  INT           NOT NULL,      -- Sales.Store.BusinessEntityID
    ResellerName          NVARCHAR(50)  NOT NULL,
    BusinessType          NVARCHAR(30)  NOT NULL,
    Specialty             NVARCHAR(20)  NOT NULL,
    YearOpened            SMALLINT      NULL,
    NumberEmployees       INT           NULL,
    SquareFeet            INT           NULL,
    AnnualSales           DECIMAL(19,4) NULL,
    AnnualRevenue         DECIMAL(19,4) NULL,
    BankName              NVARCHAR(50)  NULL,
    City                  NVARCHAR(30)  NOT NULL,
    StateProvinceName     NVARCHAR(50)  NOT NULL,
    PostalCode            NVARCHAR(15)  NULL,
    CountryRegionCode     NVARCHAR(3)   NOT NULL,
    CountryRegionName     NVARCHAR(50)  NOT NULL,
    ETLLoadDate           DATETIME2(0)  NOT NULL CONSTRAINT DF_DimReseller_Load DEFAULT SYSDATETIME(),
    ETLUpdateDate         DATETIME2(0)  NULL,
    CONSTRAINT UX_DimReseller_AlternateKey UNIQUE (ResellerAlternateKey)
);

-- 4.5 Sales territory (source: JSON feed)
CREATE TABLE edw.DimTerritory
(
    TerritoryKey          INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimTerritory PRIMARY KEY,
    TerritoryAlternateKey INT           NOT NULL,
    RegionName            NVARCHAR(50)  NOT NULL,
    CountryRegionCode     NVARCHAR(3)   NOT NULL,
    TerritoryGroup        NVARCHAR(50)  NOT NULL,
    CONSTRAINT UX_DimTerritory_AlternateKey UNIQUE (TerritoryAlternateKey)
);

-- 4.6 Employee (parent-child hierarchy through ParentEmployeeKey)
CREATE TABLE edw.DimEmployee
(
    EmployeeKey           INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimEmployee PRIMARY KEY,
    EmployeeAlternateKey  INT           NOT NULL,      -- HumanResources.Employee.BusinessEntityID
    ParentEmployeeKey     INT           NULL,
    OrganizationNode      NVARCHAR(100) NULL,
    OrganizationLevel     SMALLINT      NULL,
    FirstName             NVARCHAR(50)  NOT NULL,
    LastName              NVARCHAR(50)  NOT NULL,
    FullName              NVARCHAR(110) NOT NULL,
    LoginID               NVARCHAR(256) NULL,
    JobTitle              NVARCHAR(50)  NOT NULL,
    DepartmentName        NVARCHAR(50)  NOT NULL,
    DepartmentGroupName   NVARCHAR(50)  NOT NULL,
    ShiftName             NVARCHAR(50)  NOT NULL,
    Gender                NVARCHAR(10)  NOT NULL,
    MaritalStatus         NVARCHAR(10)  NOT NULL,
    BirthDate             DATE          NULL,
    HireDate              DATE          NULL,
    SalariedFlag          BIT           NULL,
    VacationHours         SMALLINT      NULL,
    SickLeaveHours        SMALLINT      NULL,
    CurrentFlag           BIT           NULL,
    IsSalesPerson         BIT           NOT NULL,
    SalesTerritoryKey     INT           NOT NULL CONSTRAINT DF_DimEmployee_Territory DEFAULT (-1),
    ETLLoadDate           DATETIME2(0)  NOT NULL CONSTRAINT DF_DimEmployee_Load DEFAULT SYSDATETIME(),
    ETLUpdateDate         DATETIME2(0)  NULL,
    CONSTRAINT UX_DimEmployee_AlternateKey UNIQUE (EmployeeAlternateKey),
    CONSTRAINT FK_DimEmployee_ParentEmployee FOREIGN KEY (ParentEmployeeKey) REFERENCES edw.DimEmployee (EmployeeKey),
    CONSTRAINT FK_DimEmployee_DimTerritory   FOREIGN KEY (SalesTerritoryKey) REFERENCES edw.DimTerritory (TerritoryKey)
);

-- 4.7 Promotion (source: XML file)
CREATE TABLE edw.DimPromotion
(
    PromotionKey          INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimPromotion PRIMARY KEY,
    PromotionAlternateKey INT           NOT NULL,
    PromotionName         NVARCHAR(255) NOT NULL,
    DiscountPct           DECIMAL(10,4) NOT NULL,
    PromotionType         NVARCHAR(50)  NOT NULL,
    PromotionCategory     NVARCHAR(50)  NOT NULL,
    StartDate             DATE          NULL,
    EndDate               DATE          NULL,
    CONSTRAINT UX_DimPromotion_AlternateKey UNIQUE (PromotionAlternateKey)
);

-- 4.8 Sales reason
CREATE TABLE edw.DimSalesReason
(
    SalesReasonKey          INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimSalesReason PRIMARY KEY,
    SalesReasonAlternateKey INT          NOT NULL,
    SalesReasonName         NVARCHAR(50) NOT NULL,
    SalesReasonType         NVARCHAR(50) NOT NULL,
    CONSTRAINT UX_DimSalesReason_AlternateKey UNIQUE (SalesReasonAlternateKey)
);

-- 4.9 Vendor
CREATE TABLE edw.DimVendor
(
    VendorKey             INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimVendor PRIMARY KEY,
    VendorAlternateKey    INT           NOT NULL,      -- Purchasing.Vendor.BusinessEntityID
    AccountNumber         NVARCHAR(15)  NULL,
    VendorName            NVARCHAR(50)  NOT NULL,
    CreditRating          TINYINT       NULL,
    CreditRatingDesc      NVARCHAR(20)  NOT NULL,
    PreferredVendorFlag   BIT           NULL,
    ActiveFlag            BIT           NULL,
    City                  NVARCHAR(30)  NOT NULL,
    StateProvinceName     NVARCHAR(50)  NOT NULL,
    CountryRegionCode     NVARCHAR(3)   NOT NULL,
    CONSTRAINT UX_DimVendor_AlternateKey UNIQUE (VendorAlternateKey)
);

-- 4.10 Ship method (conformed: used by sales and purchasing)
CREATE TABLE edw.DimShipMethod
(
    ShipMethodKey          INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimShipMethod PRIMARY KEY,
    ShipMethodAlternateKey INT           NOT NULL,
    ShipMethodName         NVARCHAR(50)  NOT NULL,
    ShipBase               DECIMAL(19,4) NULL,
    ShipRate               DECIMAL(19,4) NULL,
    CONSTRAINT UX_DimShipMethod_AlternateKey UNIQUE (ShipMethodAlternateKey)
);

-- 4.11 Location (warehouse / production locations)
CREATE TABLE edw.DimLocation
(
    LocationKey            INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimLocation PRIMARY KEY,
    LocationAlternateKey   SMALLINT      NOT NULL,
    LocationName           NVARCHAR(50)  NOT NULL,
    CostRate               DECIMAL(10,4) NULL,
    Availability           DECIMAL(8,2)  NULL,
    CONSTRAINT UX_DimLocation_AlternateKey UNIQUE (LocationAlternateKey)
);

-- 4.12 Scrap reason
CREATE TABLE edw.DimScrapReason
(
    ScrapReasonKey          INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimScrapReason PRIMARY KEY,
    ScrapReasonAlternateKey SMALLINT     NOT NULL,
    ScrapReasonName         NVARCHAR(50) NOT NULL,
    CONSTRAINT UX_DimScrapReason_AlternateKey UNIQUE (ScrapReasonAlternateKey)
);

-- 4.13 Currency
CREATE TABLE edw.DimCurrency
(
    CurrencyKey            INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimCurrency PRIMARY KEY,
    CurrencyAlternateKey   NCHAR(3)      NOT NULL,
    CurrencyName           NVARCHAR(50)  NOT NULL,
    CONSTRAINT UX_DimCurrency_AlternateKey UNIQUE (CurrencyAlternateKey)
);
GO


/*==============================================================================
    5. EDW FACT TABLES
==============================================================================*/

-- 5.1 Sales (transaction fact) 
CREATE TABLE edw.FactSales
(
    SalesOrderLineKey      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_FactSales PRIMARY KEY,
    SalesOrderNumber       NVARCHAR(25)  NOT NULL,     -- degenerate dimension
    SalesOrderLineNumber   SMALLINT      NOT NULL,
    SalesChannel           NVARCHAR(10)  NOT NULL,     -- Internet / Reseller
    OnlineOrderFlag        BIT           NOT NULL,
    OrderDateKey           INT NOT NULL,
    DueDateKey             INT NOT NULL,
    ShipDateKey            INT NOT NULL,
    ProductKey             INT NOT NULL,
    CustomerKey            INT NOT NULL,               -- -1 for reseller orders
    ResellerKey            INT NOT NULL,               -- -1 for internet orders
    EmployeeKey            INT NOT NULL,               -- sales person, -1 when none
    TerritoryKey           INT NOT NULL,
    PromotionKey           INT NOT NULL,
    ShipMethodKey          INT NOT NULL,
    CurrencyKey            INT NOT NULL,
    OrderQuantity          INT           NOT NULL,
    UnitPrice              DECIMAL(19,4) NOT NULL,
    ExtendedAmount         DECIMAL(19,4) NOT NULL,     -- OrderQuantity x UnitPrice
    UnitPriceDiscountPct   DECIMAL(10,4) NOT NULL,
    DiscountAmount         DECIMAL(19,4) NOT NULL,
    SalesAmount            DECIMAL(19,4) NOT NULL,     -- ExtendedAmount - DiscountAmount
    ProductStandardCost    DECIMAL(19,4) NOT NULL,     -- unit cost valid on the order date
    TotalProductCost       DECIMAL(19,4) NOT NULL,
    GrossProfit            DECIMAL(19,4) NOT NULL,
    TaxAmount              DECIMAL(19,4) NOT NULL,     -- header tax allocated to the line
    FreightAmount          DECIMAL(19,4) NOT NULL,     -- header freight allocated to the line
    CONSTRAINT UX_FactSales_Grain UNIQUE (SalesOrderNumber, SalesOrderLineNumber),
    CONSTRAINT FK_FactSales_OrderDate   FOREIGN KEY (OrderDateKey)  REFERENCES edw.DimDate (DateKey),
    CONSTRAINT FK_FactSales_DueDate     FOREIGN KEY (DueDateKey)    REFERENCES edw.DimDate (DateKey),
    CONSTRAINT FK_FactSales_ShipDate    FOREIGN KEY (ShipDateKey)   REFERENCES edw.DimDate (DateKey),
    CONSTRAINT FK_FactSales_DimProduct  FOREIGN KEY (ProductKey)    REFERENCES edw.DimProduct (ProductKey),
    CONSTRAINT FK_FactSales_DimCustomer FOREIGN KEY (CustomerKey)   REFERENCES edw.DimCustomer (CustomerKey),
    CONSTRAINT FK_FactSales_DimReseller FOREIGN KEY (ResellerKey)   REFERENCES edw.DimReseller (ResellerKey),
    CONSTRAINT FK_FactSales_DimEmployee FOREIGN KEY (EmployeeKey)   REFERENCES edw.DimEmployee (EmployeeKey),
    CONSTRAINT FK_FactSales_DimTerritory FOREIGN KEY (TerritoryKey) REFERENCES edw.DimTerritory (TerritoryKey),
    CONSTRAINT FK_FactSales_DimPromotion FOREIGN KEY (PromotionKey) REFERENCES edw.DimPromotion (PromotionKey),
    CONSTRAINT FK_FactSales_DimShipMethod FOREIGN KEY (ShipMethodKey) REFERENCES edw.DimShipMethod (ShipMethodKey),
    CONSTRAINT FK_FactSales_DimCurrency FOREIGN KEY (CurrencyKey)   REFERENCES edw.DimCurrency (CurrencyKey)
);

-- 5.2 Sales reason (factless fact) 
CREATE TABLE edw.FactSalesReason
(
    SalesOrderNumber       NVARCHAR(25) NOT NULL,
    SalesReasonKey         INT NOT NULL,
    OrderDateKey           INT NOT NULL,
    CustomerKey            INT NOT NULL,
    TerritoryKey           INT NOT NULL,
    CONSTRAINT PK_FactSalesReason PRIMARY KEY (SalesOrderNumber, SalesReasonKey),
    CONSTRAINT FK_FactSalesReason_DimSalesReason FOREIGN KEY (SalesReasonKey) REFERENCES edw.DimSalesReason (SalesReasonKey),
    CONSTRAINT FK_FactSalesReason_OrderDate      FOREIGN KEY (OrderDateKey)   REFERENCES edw.DimDate (DateKey),
    CONSTRAINT FK_FactSalesReason_DimCustomer    FOREIGN KEY (CustomerKey)    REFERENCES edw.DimCustomer (CustomerKey),
    CONSTRAINT FK_FactSalesReason_DimTerritory   FOREIGN KEY (TerritoryKey)   REFERENCES edw.DimTerritory (TerritoryKey)
);

-- 5.3 Sales quota (periodic) 
CREATE TABLE edw.FactSalesQuota
(
    SalesQuotaKey          INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_FactSalesQuota PRIMARY KEY,
    EmployeeKey            INT NOT NULL,
    QuotaDateKey           INT NOT NULL,
    SalesAmountQuota       DECIMAL(19,4) NOT NULL,
    CONSTRAINT UX_FactSalesQuota_Grain UNIQUE (EmployeeKey, QuotaDateKey),
    CONSTRAINT FK_FactSalesQuota_DimEmployee FOREIGN KEY (EmployeeKey)  REFERENCES edw.DimEmployee (EmployeeKey),
    CONSTRAINT FK_FactSalesQuota_QuotaDate   FOREIGN KEY (QuotaDateKey) REFERENCES edw.DimDate (DateKey)
);

-- 5.4 Purchases (transaction fact) 
CREATE TABLE edw.FactPurchases
(
    PurchaseOrderLineKey   INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_FactPurchases PRIMARY KEY,
    PurchaseOrderNumber    NVARCHAR(25)  NOT NULL,     -- degenerate dimension
    PurchaseOrderLineNumber SMALLINT     NOT NULL,
    OrderStatus            NVARCHAR(15)  NOT NULL,
    OrderDateKey           INT NOT NULL,
    DueDateKey             INT NOT NULL,
    ShipDateKey            INT NOT NULL,
    ProductKey             INT NOT NULL,
    VendorKey              INT NOT NULL,
    EmployeeKey            INT NOT NULL,               -- purchasing agent
    ShipMethodKey          INT NOT NULL,
    OrderQuantity          INT           NOT NULL,
    UnitPrice              DECIMAL(19,4) NOT NULL,
    LineTotal              DECIMAL(19,4) NOT NULL,
    ReceivedQuantity       DECIMAL(10,2) NOT NULL,
    RejectedQuantity       DECIMAL(10,2) NOT NULL,
    StockedQuantity        DECIMAL(10,2) NOT NULL,
    TaxAmount              DECIMAL(19,4) NOT NULL,
    FreightAmount          DECIMAL(19,4) NOT NULL,
    CONSTRAINT UX_FactPurchases_Grain UNIQUE (PurchaseOrderNumber, PurchaseOrderLineNumber),
    CONSTRAINT FK_FactPurchases_OrderDate    FOREIGN KEY (OrderDateKey)  REFERENCES edw.DimDate (DateKey),
    CONSTRAINT FK_FactPurchases_DueDate      FOREIGN KEY (DueDateKey)    REFERENCES edw.DimDate (DateKey),
    CONSTRAINT FK_FactPurchases_ShipDate     FOREIGN KEY (ShipDateKey)   REFERENCES edw.DimDate (DateKey),
    CONSTRAINT FK_FactPurchases_DimProduct   FOREIGN KEY (ProductKey)    REFERENCES edw.DimProduct (ProductKey),
    CONSTRAINT FK_FactPurchases_DimVendor    FOREIGN KEY (VendorKey)     REFERENCES edw.DimVendor (VendorKey),
    CONSTRAINT FK_FactPurchases_DimEmployee  FOREIGN KEY (EmployeeKey)   REFERENCES edw.DimEmployee (EmployeeKey),
    CONSTRAINT FK_FactPurchases_DimShipMethod FOREIGN KEY (ShipMethodKey) REFERENCES edw.DimShipMethod (ShipMethodKey)
);

-- 5.5 Production work orders (accumulating-style fact) 
CREATE TABLE edw.FactProductionWorkOrder
(
    WorkOrderKey           INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_FactProductionWorkOrder PRIMARY KEY,
    WorkOrderNumber        INT NOT NULL,               -- degenerate dimension
    ProductKey             INT NOT NULL,
    StartDateKey           INT NOT NULL,
    EndDateKey             INT NOT NULL,
    DueDateKey             INT NOT NULL,
    ScrapReasonKey         INT NOT NULL,
    OrderQuantity          INT           NOT NULL,
    StockedQuantity        INT           NOT NULL,
    ScrappedQuantity       INT           NOT NULL,
    ProductionDays         INT           NULL,
    DaysLate               INT           NOT NULL,
    OperationCount         INT           NOT NULL,
    PlannedCost            DECIMAL(19,4) NOT NULL,
    ActualCost             DECIMAL(19,4) NOT NULL,
    ActualResourceHours    DECIMAL(10,4) NOT NULL,
    CONSTRAINT UX_FactProductionWorkOrder_Grain UNIQUE (WorkOrderNumber),
    CONSTRAINT FK_FactProduction_DimProduct  FOREIGN KEY (ProductKey)     REFERENCES edw.DimProduct (ProductKey),
    CONSTRAINT FK_FactProduction_StartDate   FOREIGN KEY (StartDateKey)   REFERENCES edw.DimDate (DateKey),
    CONSTRAINT FK_FactProduction_EndDate     FOREIGN KEY (EndDateKey)     REFERENCES edw.DimDate (DateKey),
    CONSTRAINT FK_FactProduction_DueDate     FOREIGN KEY (DueDateKey)     REFERENCES edw.DimDate (DateKey),
    CONSTRAINT FK_FactProduction_DimScrapReason FOREIGN KEY (ScrapReasonKey) REFERENCES edw.DimScrapReason (ScrapReasonKey)
);

-- 5.6 Inventory transactions (transaction fact) 
CREATE TABLE edw.FactInventoryTransaction
(
    InventoryTransactionKey INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_FactInventoryTransaction PRIMARY KEY,
    TransactionAlternateKey INT          NOT NULL,     -- TransactionID (current + archive)
    TransactionDateKey     INT           NOT NULL,
    ProductKey             INT           NOT NULL,
    TransactionType        NCHAR(1)      NOT NULL,     -- W / S / P
    TransactionTypeName    NVARCHAR(20)  NOT NULL,     -- Work Order / Sales Order / Purchase Order
    ReferenceOrderID       INT           NOT NULL,
    ReferenceOrderLineID   INT           NOT NULL,
    SourceTable            NVARCHAR(10)  NOT NULL,     -- Current / Archive
    Quantity               INT           NOT NULL,
    ActualCost             DECIMAL(19,4) NOT NULL,
    CONSTRAINT UX_FactInventoryTransaction_Grain UNIQUE (TransactionAlternateKey),
    CONSTRAINT FK_FactInvTxn_TransactionDate FOREIGN KEY (TransactionDateKey) REFERENCES edw.DimDate (DateKey),
    CONSTRAINT FK_FactInvTxn_DimProduct      FOREIGN KEY (ProductKey)         REFERENCES edw.DimProduct (ProductKey)
);

-- 5.7 Inventory snapshot (periodic snapshot)
CREATE TABLE edw.FactInventorySnapshot
(
    SnapshotDateKey        INT          NOT NULL,
    ProductKey             INT          NOT NULL,
    LocationKey            INT          NOT NULL,
    Shelf                  NVARCHAR(10) NULL,
    Bin                    TINYINT      NULL,
    QuantityOnHand         INT          NOT NULL,
    CONSTRAINT PK_FactInventorySnapshot PRIMARY KEY (SnapshotDateKey, ProductKey, LocationKey),
    CONSTRAINT FK_FactInvSnap_SnapshotDate FOREIGN KEY (SnapshotDateKey) REFERENCES edw.DimDate (DateKey),
    CONSTRAINT FK_FactInvSnap_DimProduct   FOREIGN KEY (ProductKey)      REFERENCES edw.DimProduct (ProductKey),
    CONSTRAINT FK_FactInvSnap_DimLocation  FOREIGN KEY (LocationKey)     REFERENCES edw.DimLocation (LocationKey)
);

-- 5.8 Currency rates (daily) 
CREATE TABLE edw.FactCurrencyRate
(
    CurrencyKey            INT           NOT NULL,
    DateKey                INT           NOT NULL,
    AverageRate            DECIMAL(19,4) NOT NULL,
    EndOfDayRate           DECIMAL(19,4) NOT NULL,
    CONSTRAINT PK_FactCurrencyRate PRIMARY KEY (CurrencyKey, DateKey),
    CONSTRAINT FK_FactCurrencyRate_DimCurrency FOREIGN KEY (CurrencyKey) REFERENCES edw.DimCurrency (CurrencyKey),
    CONSTRAINT FK_FactCurrencyRate_DimDate     FOREIGN KEY (DateKey)     REFERENCES edw.DimDate (DateKey)
);
GO


/*==============================================================================
    6. INDEXES ON FACT FOREIGN KEYS (faster star joins)
==============================================================================*/

CREATE NONCLUSTERED INDEX IX_FactSales_OrderDateKey  ON edw.FactSales (OrderDateKey);
CREATE NONCLUSTERED INDEX IX_FactSales_ProductKey    ON edw.FactSales (ProductKey);
CREATE NONCLUSTERED INDEX IX_FactSales_CustomerKey   ON edw.FactSales (CustomerKey);
CREATE NONCLUSTERED INDEX IX_FactSales_ResellerKey   ON edw.FactSales (ResellerKey);
CREATE NONCLUSTERED INDEX IX_FactSales_TerritoryKey  ON edw.FactSales (TerritoryKey);
CREATE NONCLUSTERED INDEX IX_FactSales_Channel       ON edw.FactSales (SalesChannel) INCLUDE (SalesAmount, OrderQuantity);
CREATE NONCLUSTERED INDEX IX_FactPurchases_OrderDateKey ON edw.FactPurchases (OrderDateKey);
CREATE NONCLUSTERED INDEX IX_FactPurchases_VendorKey    ON edw.FactPurchases (VendorKey);
CREATE NONCLUSTERED INDEX IX_FactProduction_ProductKey  ON edw.FactProductionWorkOrder (ProductKey);
CREATE NONCLUSTERED INDEX IX_FactInvTxn_DateProduct     ON edw.FactInventoryTransaction (TransactionDateKey, ProductKey);
GO

PRINT 'Script 01 completed: database, schemas, ETL control objects and EDW tables created.';
GO

SET NOEXEC OFF;
GO
