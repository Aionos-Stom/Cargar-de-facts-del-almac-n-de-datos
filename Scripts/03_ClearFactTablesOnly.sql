-- =============================================
-- Script para Limpiar Únicamente las Tablas de Hechos
-- Use este script cuando solo necesite limpiar los facts sin recargarlos
-- =============================================

USE [BusinessIntelligenceDW]
GO

-- Verificar que las tablas existen
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FactSales]') AND type in (N'U'))
BEGIN
    PRINT 'ERROR: La tabla FactSales no existe.';
    RETURN;
END

PRINT '========================================';
PRINT 'Iniciando limpieza de tablas de hechos...';
PRINT 'Hora de inicio: ' + CONVERT(NVARCHAR, GETDATE(), 120);
PRINT '========================================';
PRINT '';

-- Mostrar cantidad de registros antes de limpiar
DECLARE @CountBefore INT;
SELECT @CountBefore = COUNT(*) FROM [dbo].[FactSales];
PRINT 'Registros en FactSales antes de limpiar: ' + CAST(@CountBefore AS NVARCHAR(10));
PRINT '';

-- Ejecutar limpieza
DECLARE @Result INT;
EXEC @Result = [dbo].[sp_ClearFactSales];

IF @Result = 0
BEGIN
    -- Verificar que se limpió correctamente
    DECLARE @CountAfter INT;
    SELECT @CountAfter = COUNT(*) FROM [dbo].[FactSales];
    
    PRINT '';
    PRINT '========================================';
    PRINT 'Limpieza completada exitosamente';
    PRINT 'Hora de finalización: ' + CONVERT(NVARCHAR, GETDATE(), 120);
    PRINT 'Registros eliminados: ' + CAST(@CountBefore AS NVARCHAR(10));
    PRINT 'Registros restantes: ' + CAST(@CountAfter AS NVARCHAR(10));
    PRINT '========================================';
END
ELSE
BEGIN
    PRINT '';
    PRINT 'ERROR: La limpieza falló. Revise los mensajes de error anteriores.';
END
GO

