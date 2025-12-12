-- =============================================
-- Script de Ejecución del Proceso de Carga de Facts
-- Este script ejecuta el proceso completo de limpieza y carga
-- =============================================

USE [BusinessIntelligenceDW]
GO

-- Verificar que las tablas existen
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FactSales]') AND type in (N'U'))
BEGIN
    PRINT 'ERROR: La tabla FactSales no existe. Por favor ejecute primero el script 01_CreateDataWarehouseTables.sql';
    RETURN;
END

-- Verificar que las dimensiones tienen datos
DECLARE @DimCustomerCount INT;
DECLARE @DimProductCount INT;
DECLARE @DimDateCount INT;

SELECT @DimCustomerCount = COUNT(*) FROM [dbo].[DimCustomers];
SELECT @DimProductCount = COUNT(*) FROM [dbo].[DimProducts];
SELECT @DimDateCount = COUNT(*) FROM [dbo].[DimDates];

IF @DimCustomerCount = 0
BEGIN
    PRINT 'ADVERTENCIA: La tabla DimCustomers está vacía. Asegúrese de cargar las dimensiones primero.';
END

IF @DimProductCount = 0
BEGIN
    PRINT 'ADVERTENCIA: La tabla DimProducts está vacía. Asegúrese de cargar las dimensiones primero.';
END

IF @DimDateCount = 0
BEGIN
    PRINT 'ADVERTENCIA: La tabla DimDates está vacía. Asegúrese de cargar las dimensiones primero.';
END

-- Verificar que las tablas operacionales tienen datos
DECLARE @OrderCount INT;
DECLARE @OrderDetailCount INT;

SELECT @OrderCount = COUNT(*) FROM [dbo].[Orders];
SELECT @OrderDetailCount = COUNT(*) FROM [dbo].[OrderDetails];

IF @OrderCount = 0
BEGIN
    PRINT 'ERROR: La tabla Orders está vacía. No se pueden cargar los facts sin datos operacionales.';
    RETURN;
END

IF @OrderDetailCount = 0
BEGIN
    PRINT 'ERROR: La tabla OrderDetails está vacía. No se pueden cargar los facts sin datos operacionales.';
    RETURN;
END

PRINT '========================================';
PRINT 'Verificación de datos completada:';
PRINT '  - DimCustomers: ' + CAST(@DimCustomerCount AS NVARCHAR(10)) + ' registros';
PRINT '  - DimProducts: ' + CAST(@DimProductCount AS NVARCHAR(10)) + ' registros';
PRINT '  - DimDates: ' + CAST(@DimDateCount AS NVARCHAR(10)) + ' registros';
PRINT '  - Orders: ' + CAST(@OrderCount AS NVARCHAR(10)) + ' registros';
PRINT '  - OrderDetails: ' + CAST(@OrderDetailCount AS NVARCHAR(10)) + ' registros';
PRINT '========================================';
PRINT '';

-- Ejecutar el proceso completo de actualización
DECLARE @Result INT;
EXEC @Result = [dbo].[sp_RefreshFactSales];

IF @Result >= 0
BEGIN
    -- Mostrar estadísticas finales
    DECLARE @TotalFacts INT;
    SELECT @TotalFacts = COUNT(*) FROM [dbo].[FactSales];
    
    PRINT '';
    PRINT '========================================';
    PRINT 'ESTADÍSTICAS FINALES:';
    PRINT '  Total de registros en FactSales: ' + CAST(@TotalFacts AS NVARCHAR(10));
    PRINT '========================================';
    
    -- Mostrar muestra de datos cargados
    PRINT '';
    PRINT 'Muestra de datos cargados (primeros 5 registros):';
    SELECT TOP 5
        fs.FactSalesId,
        fs.OrderId,
        dc.FirstName + ' ' + dc.LastName AS CustomerName,
        dp.ProductName,
        dd.Date AS OrderDate,
        fs.Quantity,
        fs.TotalPrice,
        fs.OrderStatus
    FROM [dbo].[FactSales] fs
    INNER JOIN [dbo].[DimCustomers] dc ON fs.CustomerKey = dc.CustomerKey
    INNER JOIN [dbo].[DimProducts] dp ON fs.ProductKey = dp.ProductKey
    INNER JOIN [dbo].[DimDates] dd ON fs.DateKey = dd.DateKey
    ORDER BY fs.FactSalesId;
END
ELSE
BEGIN
    PRINT 'ERROR: El proceso de carga falló. Revise los mensajes de error anteriores.';
END
GO

