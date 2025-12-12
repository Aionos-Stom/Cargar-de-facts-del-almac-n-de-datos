-- =============================================
-- Script de Creación de Tablas del Data Warehouse
-- Base de Datos: BusinessIntelligenceDW
-- =============================================

USE [BusinessIntelligenceDW]
GO

-- =============================================
-- TABLAS DE DIMENSIONES
-- =============================================

-- Tabla DimCustomer
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DimCustomers]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[DimCustomers](
        [CustomerKey] [int] IDENTITY(1,1) NOT NULL,
        [CustomerId] [int] NOT NULL,
        [FirstName] [nvarchar](100) NULL,
        [LastName] [nvarchar](100) NULL,
        [Email] [nvarchar](255) NULL,
        [Phone] [nvarchar](50) NULL,
        [City] [nvarchar](100) NULL,
        [Country] [nvarchar](100) NULL,
        [Region] [nvarchar](100) NULL,
        [CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
        [ModifiedDate] [datetime] NULL,
        [IsActive] [bit] NOT NULL DEFAULT 1,
        CONSTRAINT [PK_DimCustomers] PRIMARY KEY CLUSTERED ([CustomerKey] ASC)
    )
    
    CREATE NONCLUSTERED INDEX [IX_DimCustomers_CustomerId] ON [dbo].[DimCustomers]([CustomerId])
    CREATE NONCLUSTERED INDEX [IX_DimCustomers_Country_City] ON [dbo].[DimCustomers]([Country], [City])
END
GO

-- Tabla DimProduct
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DimProducts]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[DimProducts](
        [ProductKey] [int] IDENTITY(1,1) NOT NULL,
        [ProductId] [int] NOT NULL,
        [ProductName] [nvarchar](200) NULL,
        [Category] [nvarchar](100) NULL,
        [Subcategory] [nvarchar](100) NULL,
        [Price] [decimal](18, 2) NULL,
        [Stock] [int] NULL,
        [Brand] [nvarchar](100) NULL,
        [SKU] [nvarchar](50) NULL,
        [CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
        [ModifiedDate] [datetime] NULL,
        [IsActive] [bit] NOT NULL DEFAULT 1,
        CONSTRAINT [PK_DimProducts] PRIMARY KEY CLUSTERED ([ProductKey] ASC)
    )
    
    CREATE NONCLUSTERED INDEX [IX_DimProducts_ProductId] ON [dbo].[DimProducts]([ProductId])
    CREATE NONCLUSTERED INDEX [IX_DimProducts_Category] ON [dbo].[DimProducts]([Category])
    CREATE NONCLUSTERED INDEX [IX_DimProducts_Brand] ON [dbo].[DimProducts]([Brand])
END
GO

-- Tabla DimDate
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DimDates]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[DimDates](
        [DateKey] [int] NOT NULL,
        [Date] [date] NOT NULL,
        [Year] [int] NOT NULL,
        [Quarter] [int] NOT NULL,
        [Month] [int] NOT NULL,
        [MonthName] [nvarchar](20) NULL,
        [WeekOfYear] [int] NOT NULL,
        [DayOfYear] [int] NOT NULL,
        [DayOfMonth] [int] NOT NULL,
        [DayOfWeek] [int] NOT NULL,
        [DayName] [nvarchar](20) NULL,
        [IsWeekend] [bit] NOT NULL,
        [IsHoliday] [bit] NOT NULL,
        [FiscalYear] [nvarchar](10) NULL,
        [FiscalQuarter] [int] NULL,
        [FiscalMonth] [int] NULL,
        CONSTRAINT [PK_DimDates] PRIMARY KEY CLUSTERED ([DateKey] ASC)
    )
    
    CREATE NONCLUSTERED INDEX [IX_DimDates_Date] ON [dbo].[DimDates]([Date])
    CREATE NONCLUSTERED INDEX [IX_DimDates_Year] ON [dbo].[DimDates]([Year])
    CREATE NONCLUSTERED INDEX [IX_DimDates_Year_Month] ON [dbo].[DimDates]([Year], [Month])
    CREATE NONCLUSTERED INDEX [IX_DimDates_Year_Quarter] ON [dbo].[DimDates]([Year], [Quarter])
END
GO

-- =============================================
-- TABLAS DE HECHOS (FACT TABLES)
-- =============================================

-- Tabla FactSales (Tabla de Hechos Principal de Ventas)
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FactSales]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[FactSales](
        [FactSalesId] [bigint] IDENTITY(1,1) NOT NULL,
        [CustomerKey] [int] NOT NULL,
        [ProductKey] [int] NOT NULL,
        [DateKey] [int] NOT NULL,
        [OrderId] [int] NOT NULL,
        [Quantity] [int] NOT NULL,
        [UnitPrice] [decimal](18, 2) NULL,
        [TotalPrice] [decimal](18, 2) NOT NULL,
        [OrderStatus] [nvarchar](50) NULL,
        [CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [PK_FactSales] PRIMARY KEY CLUSTERED ([FactSalesId] ASC)
    )
    
    -- Foreign Keys
    ALTER TABLE [dbo].[FactSales] WITH CHECK ADD CONSTRAINT [FK_FactSales_DimCustomers] 
        FOREIGN KEY([CustomerKey]) REFERENCES [dbo].[DimCustomers] ([CustomerKey])
    
    ALTER TABLE [dbo].[FactSales] WITH CHECK ADD CONSTRAINT [FK_FactSales_DimProducts] 
        FOREIGN KEY([ProductKey]) REFERENCES [dbo].[DimProducts] ([ProductKey])
    
    ALTER TABLE [dbo].[FactSales] WITH CHECK ADD CONSTRAINT [FK_FactSales_DimDates] 
        FOREIGN KEY([DateKey]) REFERENCES [dbo].[DimDates] ([DateKey])
    
    -- Índices para optimización de consultas
    CREATE NONCLUSTERED INDEX [IX_FactSales_CustomerKey] ON [dbo].[FactSales]([CustomerKey])
    CREATE NONCLUSTERED INDEX [IX_FactSales_ProductKey] ON [dbo].[FactSales]([ProductKey])
    CREATE NONCLUSTERED INDEX [IX_FactSales_DateKey] ON [dbo].[FactSales]([DateKey])
    CREATE NONCLUSTERED INDEX [IX_FactSales_OrderId] ON [dbo].[FactSales]([OrderId])
    CREATE NONCLUSTERED INDEX [IX_FactSales_DateKey_CustomerKey] ON [dbo].[FactSales]([DateKey], [CustomerKey])
    CREATE NONCLUSTERED INDEX [IX_FactSales_DateKey_ProductKey] ON [dbo].[FactSales]([DateKey], [ProductKey])
END
GO

-- =============================================
-- PROCEDIMIENTOS ALMACENADOS PARA LIMPIEZA
-- =============================================

-- Procedimiento para limpiar la tabla FactSales
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_ClearFactSales]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_ClearFactSales]
GO

CREATE PROCEDURE [dbo].[sp_ClearFactSales]
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Eliminar registros de FactSales
        DELETE FROM [dbo].[FactSales];
        
        -- Resetear el contador de identidad
        DBCC CHECKIDENT ('[dbo].[FactSales]', RESEED, 0);
        
        COMMIT TRANSACTION;
        
        PRINT 'Tabla FactSales limpiada exitosamente.';
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Error al limpiar FactSales: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        RETURN -1;
    END CATCH
END
GO

-- Procedimiento para limpiar todas las tablas de hechos
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_ClearAllFactTables]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_ClearAllFactTables]
GO

CREATE PROCEDURE [dbo].[sp_ClearAllFactTables]
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Limpiar FactSales
        DELETE FROM [dbo].[FactSales];
        DBCC CHECKIDENT ('[dbo].[FactSales]', RESEED, 0);
        
        COMMIT TRANSACTION;
        
        PRINT 'Todas las tablas de hechos han sido limpiadas exitosamente.';
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Error al limpiar las tablas de hechos: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        RETURN -1;
    END CATCH
END
GO

-- Procedimiento para limpiar tablas de dimensiones (opcional, usar con precaución)
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_ClearDimensionTables]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_ClearDimensionTables]
GO

CREATE PROCEDURE [dbo].[sp_ClearDimensionTables]
    @ClearDimCustomers BIT = 0,
    @ClearDimProducts BIT = 0,
    @ClearDimDates BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Limpiar DimCustomers si se solicita
        IF @ClearDimCustomers = 1
        BEGIN
            DELETE FROM [dbo].[DimCustomers];
            DBCC CHECKIDENT ('[dbo].[DimCustomers]', RESEED, 0);
            PRINT 'DimCustomers limpiada.';
        END
        
        -- Limpiar DimProducts si se solicita
        IF @ClearDimProducts = 1
        BEGIN
            DELETE FROM [dbo].[DimProducts];
            DBCC CHECKIDENT ('[dbo].[DimProducts]', RESEED, 0);
            PRINT 'DimProducts limpiada.';
        END
        
        -- Limpiar DimDates si se solicita
        IF @ClearDimDates = 1
        BEGIN
            DELETE FROM [dbo].[DimDates];
            PRINT 'DimDates limpiada.';
        END
        
        COMMIT TRANSACTION;
        
        PRINT 'Proceso de limpieza de dimensiones completado.';
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Error al limpiar las tablas de dimensiones: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        RETURN -1;
    END CATCH
END
GO

-- =============================================
-- PROCEDIMIENTO PARA CARGAR FACT SALES
-- =============================================

-- Procedimiento para cargar datos en FactSales desde las tablas operacionales
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_LoadFactSales]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_LoadFactSales]
GO

CREATE PROCEDURE [dbo].[sp_LoadFactSales]
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Insertar datos en FactSales desde Orders y OrderDetails
        INSERT INTO [dbo].[FactSales] (
            [CustomerKey],
            [ProductKey],
            [DateKey],
            [OrderId],
            [Quantity],
            [UnitPrice],
            [TotalPrice],
            [OrderStatus]
        )
        SELECT 
            dc.CustomerKey,
            dp.ProductKey,
            dd.DateKey,
            o.OrderId,
            od.Quantity,
            CASE 
                WHEN od.Quantity > 0 THEN od.TotalPrice / od.Quantity 
                ELSE 0 
            END AS UnitPrice,
            od.TotalPrice,
            o.Status AS OrderStatus
        FROM [dbo].[Orders] o
        INNER JOIN [dbo].[OrderDetails] od ON o.OrderId = od.OrderId
        INNER JOIN [dbo].[DimCustomers] dc ON o.CustomerId = dc.CustomerId
        INNER JOIN [dbo].[DimProducts] dp ON od.ProductId = dp.ProductId
        INNER JOIN [dbo].[DimDates] dd ON CAST(o.OrderDate AS DATE) = dd.Date
        WHERE NOT EXISTS (
            SELECT 1 
            FROM [dbo].[FactSales] fs 
            WHERE fs.OrderId = o.OrderId 
            AND fs.ProductKey = dp.ProductKey
        );
        
        DECLARE @RowsInserted INT = @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
        PRINT 'FactSales cargada exitosamente. Registros insertados: ' + CAST(@RowsInserted AS NVARCHAR(10));
        RETURN @RowsInserted;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'Error al cargar FactSales: ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        RETURN -1;
    END CATCH
END
GO

-- =============================================
-- PROCEDIMIENTO COMPLETO: LIMPIAR Y CARGAR
-- =============================================

-- Procedimiento que ejecuta limpieza y carga completa
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_RefreshFactSales]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_RefreshFactSales]
GO

CREATE PROCEDURE [dbo].[sp_RefreshFactSales]
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME = GETDATE();
    DECLARE @Result INT;
    
    PRINT '========================================';
    PRINT 'Iniciando proceso de actualización de FactSales';
    PRINT 'Hora de inicio: ' + CONVERT(NVARCHAR, @StartTime, 120);
    PRINT '========================================';
    
    -- Paso 1: Limpiar tabla
    PRINT '';
    PRINT 'Paso 1: Limpiando tabla FactSales...';
    EXEC @Result = [dbo].[sp_ClearFactSales];
    
    IF @Result <> 0
    BEGIN
        PRINT 'Error en la limpieza. Abortando proceso.';
        RETURN -1;
    END
    
    -- Paso 2: Cargar datos
    PRINT '';
    PRINT 'Paso 2: Cargando datos en FactSales...';
    EXEC @Result = [dbo].[sp_LoadFactSales];
    
    IF @Result < 0
    BEGIN
        PRINT 'Error en la carga. Abortando proceso.';
        RETURN -1;
    END
    
    DECLARE @EndTime DATETIME = GETDATE();
    DECLARE @Duration INT = DATEDIFF(SECOND, @StartTime, @EndTime);
    
    PRINT '';
    PRINT '========================================';
    PRINT 'Proceso completado exitosamente';
    PRINT 'Hora de finalización: ' + CONVERT(NVARCHAR, @EndTime, 120);
    PRINT 'Duración: ' + CAST(@Duration AS NVARCHAR(10)) + ' segundos';
    PRINT 'Registros cargados: ' + CAST(@Result AS NVARCHAR(10));
    PRINT '========================================';
    
    RETURN @Result;
END
GO

PRINT 'Script de creación de tablas y procedimientos completado exitosamente.'
GO

