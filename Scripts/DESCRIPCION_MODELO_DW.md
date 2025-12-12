# Descripción del Modelo de Base de Datos Analítica (Data Warehouse)

## 1. Arquitectura del Modelo

### Modelo Estrella (Star Schema)

El modelo implementado sigue la arquitectura **Star Schema** (Modelo Estrella), que es la más adecuada para análisis de ventas y Business Intelligence. Esta arquitectura se caracteriza por:

- **Tabla de Hechos Central (Fact Table)**: `FactSales` - Contiene las métricas y medidas de negocio
- **Tablas de Dimensiones (Dimension Tables)**: Rodean la tabla de hechos y proporcionan contexto descriptivo
  - `DimCustomers` - Información de clientes
  - `DimProducts` - Información de productos
  - `DimDates` - Información temporal desnormalizada

### Ventajas del Modelo Estrella

1. **Simplicidad**: Fácil de entender y consultar para usuarios de negocio
2. **Rendimiento**: Consultas más rápidas debido a la desnormalización y pocos JOINs
3. **Escalabilidad**: Permite agregar nuevas dimensiones sin afectar la estructura existente
4. **Optimización**: Índices estratégicos mejoran el rendimiento de consultas analíticas

## 2. Estructura de Tablas

### 2.1 Tablas de Dimensiones

#### DimCustomers (Dimensión de Clientes)
- **Propósito**: Almacena información descriptiva de los clientes
- **Clave Surrogate**: `CustomerKey` (PK, auto-incremental)
- **Clave de Negocio**: `CustomerId` (ID del sistema operacional)
- **Atributos Descriptivos**:
  - Información personal: `FirstName`, `LastName`, `Email`, `Phone`
  - Ubicación geográfica: `City`, `Country`, `Region`
  - Control temporal: `CreatedDate`, `ModifiedDate`, `IsActive`

**Decisión de Diseño**: Se incluye `Region` para permitir análisis geográfico más granular que solo país/ciudad.

#### DimProducts (Dimensión de Productos)
- **Propósito**: Almacena información descriptiva de los productos
- **Clave Surrogate**: `ProductKey` (PK, auto-incremental)
- **Clave de Negocio**: `ProductId` (ID del sistema operacional)
- **Atributos Descriptivos**:
  - Información básica: `ProductName`, `Category`, `Subcategory`
  - Información comercial: `Price`, `Stock`, `Brand`, `SKU`
  - Control temporal: `CreatedDate`, `ModifiedDate`, `IsActive`

**Decisión de Diseño**: Se incluyen `Subcategory` y `Brand` para permitir análisis más detallados por segmentos de producto.

#### DimDates (Dimensión de Tiempo)
- **Propósito**: Almacena información temporal desnormalizada para análisis por tiempo
- **Clave Surrogate**: `DateKey` (PK, formato YYYYMMDD como entero)
- **Atributos Descriptivos**:
  - Niveles temporales: `Year`, `Quarter`, `Month`, `MonthName`, `WeekOfYear`
  - Información del día: `DayOfYear`, `DayOfMonth`, `DayOfWeek`, `DayName`
  - Indicadores: `IsWeekend`, `IsHoliday`
  - Período fiscal: `FiscalYear`, `FiscalQuarter`, `FiscalMonth`

**Decisión de Diseño**: Se incluye información fiscal para permitir análisis por períodos contables, además de calendario gregoriano.

### 2.2 Tabla de Hechos

#### FactSales (Tabla de Hechos de Ventas)
- **Propósito**: Almacena las transacciones de ventas con sus métricas
- **Clave Primaria**: `FactSalesId` (PK, auto-incremental)
- **Claves Foráneas** (Relaciones con Dimensiones):
  - `CustomerKey` → `DimCustomers.CustomerKey`
  - `ProductKey` → `DimProducts.ProductKey`
  - `DateKey` → `DimDates.DateKey`
- **Medidas (Métricas de Negocio)**:
  - `Quantity`: Cantidad de productos vendidos
  - `UnitPrice`: Precio unitario (calculado)
  - `TotalPrice`: Precio total de la transacción
- **Atributos Adicionales**:
  - `OrderId`: Referencia a la orden original
  - `OrderStatus`: Estado de la orden (Shipped, Delivered, Cancelled, etc.)
  - `CreatedDate`: Fecha de carga del registro

**Decisión de Diseño**: Se almacena `UnitPrice` calculado para evitar recalcularlo en cada consulta, mejorando el rendimiento.

## 3. Integridad Referencial

### Relaciones Implementadas

1. **FactSales → DimCustomers**
   - Relación: Muchos a Uno
   - Restricción: `FK_FactSales_DimCustomers`
   - Comportamiento: Restrict (no permite eliminar clientes con ventas)

2. **FactSales → DimProducts**
   - Relación: Muchos a Uno
   - Restricción: `FK_FactSales_DimProducts`
   - Comportamiento: Restrict (no permite eliminar productos con ventas)

3. **FactSales → DimDates**
   - Relación: Muchos a Uno
   - Restricción: `FK_FactSales_DimDates`
   - Comportamiento: Restrict (no permite eliminar fechas con ventas)

### Garantías de Integridad

- **Integridad Referencial**: Las claves foráneas garantizan que solo existan ventas para clientes, productos y fechas válidas
- **Consistencia de Datos**: Las restricciones evitan datos huérfanos
- **Validación**: Los procedimientos almacenados validan la existencia de dimensiones antes de insertar facts

## 4. Optimización y Rendimiento

### Índices Implementados

#### En Tablas de Dimensiones:
- **DimCustomers**: 
  - Índice en `CustomerId` (búsqueda rápida por ID operacional)
  - Índice compuesto en `Country, City` (análisis geográfico)
  
- **DimProducts**:
  - Índice en `ProductId` (búsqueda rápida por ID operacional)
  - Índice en `Category` (filtrado por categoría)
  - Índice en `Brand` (análisis por marca)

- **DimDates**:
  - Índice en `Date` (búsqueda por fecha exacta)
  - Índice en `Year` (análisis anual)
  - Índice compuesto en `Year, Month` (análisis mensual)
  - Índice compuesto en `Year, Quarter` (análisis trimestral)

#### En Tabla de Hechos:
- Índices individuales en cada clave foránea (`CustomerKey`, `ProductKey`, `DateKey`)
- Índice en `OrderId` (búsqueda por orden específica)
- Índices compuestos para consultas comunes:
  - `DateKey, CustomerKey` (ventas por cliente en tiempo)
  - `DateKey, ProductKey` (ventas por producto en tiempo)

**Decisión de Diseño**: Los índices compuestos optimizan las consultas más frecuentes (análisis por tiempo + dimensión).

## 5. Proceso ETL (Extract, Transform, Load)

### Fuentes de Datos Integradas

El modelo soporta la integración de datos desde tres fuentes principales:

1. **Archivos CSV**: 
   - `customers.csv`, `products.csv`, `orders.csv`, `order_details.csv`
   - Extracción mediante `CsvExtractor`

2. **API REST Externa**:
   - Actualización de datos de productos y clientes
   - Extracción mediante `ApiExtractor`

3. **Base de Datos Externa (SQL Server)**:
   - Historial de ventas de años anteriores
   - Extracción mediante `DatabaseExtractor`

### Proceso de Carga

1. **Extracción (Extract)**: Datos obtenidos de las fuentes mencionadas
2. **Transformación (Transform)**: 
   - Normalización de datos
   - Validación de integridad
   - Cálculo de campos derivados (UnitPrice)
   - Mapeo a claves surrogate de dimensiones
3. **Carga (Load)**:
   - Carga incremental de dimensiones
   - Limpieza y recarga de tabla de hechos mediante `sp_RefreshFactSales`

## 6. Capacidades Analíticas

El modelo permite responder a las siguientes categorías de preguntas:

### 6.1 Análisis General de Ventas
- Total de ventas global: `SUM(TotalPrice)`
- Promedio de ventas por transacción: `AVG(TotalPrice)`
- Volumen de ventas por periodo: Agrupación por `DimDates`
- Ventas por geografía: Agrupación por `DimCustomers.Country/Region/City`

### 6.2 Ventas por Producto
- Productos más vendidos: `SUM(Quantity) GROUP BY ProductKey`
- Productos con mayor ingreso: `SUM(TotalPrice) GROUP BY ProductKey`
- Evolución temporal: `SUM(TotalPrice) GROUP BY ProductKey, DateKey`
- Precio promedio: `AVG(UnitPrice) GROUP BY ProductKey`

### 6.3 Ventas por Cliente
- Clientes con más compras: `COUNT(DISTINCT OrderId) GROUP BY CustomerKey`
- Clientes con mayor volumen: `SUM(TotalPrice) GROUP BY CustomerKey`
- Promedio de productos por transacción: `AVG(Quantity) GROUP BY CustomerKey`
- Segmentación geográfica: Agrupación por `Country/Region/City`

### 6.4 Tendencias Temporales
- Tendencias mensuales/trimestrales: Agrupación por `DimDates.Month/Quarter`
- Estacionalidad: Análisis por `DimDates.MonthName` y `DimDates.Quarter`
- Evolución anual: Comparación por `DimDates.Year`

### 6.5 Comparativas y Desempeño
- Comparación entre categorías: `SUM(TotalPrice) GROUP BY DimProducts.Category`
- Porcentaje por categoría: Cálculo de porcentajes sobre total
- Comparación año sobre año: `DimDates.Year` comparativo

### 6.6 Indicadores Clave (KPIs)
- Total de ventas: `SUM(TotalPrice)`
- Top 5 productos: `TOP 5 ORDER BY SUM(TotalPrice) DESC`
- Top 5 clientes: `TOP 5 ORDER BY SUM(TotalPrice) DESC`
- Promedio de venta por cliente: `AVG(TotalPrice) GROUP BY CustomerKey`
- Crecimiento porcentual: Cálculo de variación entre períodos

## 7. Decisiones de Diseño Clave

### 7.1 Uso de Claves Surrogate
**Decisión**: Usar claves auto-incrementales (`CustomerKey`, `ProductKey`, `DateKey`) en lugar de claves de negocio.

**Razón**: 
- Permite cambios en las claves de negocio sin afectar el historial
- Mejora el rendimiento de JOINs (enteros vs strings)
- Facilita el manejo de datos históricos (SCD - Slowly Changing Dimensions)

### 7.2 Desnormalización de DimDates
**Decisión**: Incluir todos los atributos temporales en una sola tabla en lugar de normalizar.

**Razón**:
- Reduce el número de JOINs en consultas temporales
- Mejora el rendimiento de consultas analíticas
- Facilita el análisis por múltiples niveles temporales simultáneamente

### 7.3 Almacenamiento de UnitPrice
**Decisión**: Calcular y almacenar `UnitPrice` en lugar de calcularlo en cada consulta.

**Razón**:
- Mejora el rendimiento de consultas que requieren precio unitario
- Reduce la carga computacional en tiempo de consulta
- Permite análisis histórico de precios

### 7.4 Inclusión de OrderStatus en FactSales
**Decisión**: Incluir el estado de la orden directamente en la tabla de hechos.

**Razón**:
- Permite filtrar ventas por estado (solo Shipped, excluir Cancelled, etc.)
- Facilita análisis de órdenes completadas vs canceladas
- Evita JOIN adicional con tabla de Orders

## 8. Limitaciones y Consideraciones

### Limitaciones Actuales
1. **Dimensión de Tiempo**: La dimensión de tiempo debe ser poblada manualmente o mediante proceso ETL antes de cargar facts
2. **Granularidad**: El modelo asume que cada fila en FactSales representa un producto en una orden (granularidad a nivel de línea de orden)
3. **Historial**: No implementa SCD Type 2 para cambios históricos en dimensiones (solo mantiene versión actual)

### Consideraciones Futuras
1. **SCD Type 2**: Implementar manejo de cambios históricos en dimensiones si se requiere
2. **Dimensión de Vendedores**: Agregar si se requiere análisis por vendedor
3. **Dimensión de Regiones de Venta**: Separar si se requiere análisis más complejo geográfico
4. **Tablas de Hechos Adicionales**: Considerar `FactInventory` o `FactReturns` si se requieren

## 9. Conclusión

El modelo implementado cumple con los requerimientos de un Data Warehouse analítico para análisis de ventas, proporcionando:

✅ Estructura clara y optimizada (Modelo Estrella)
✅ Integridad referencial garantizada
✅ Capacidad de responder a todas las preguntas de negocio planteadas
✅ Optimización para consultas analíticas
✅ Integración con múltiples fuentes de datos (CSV, API, DB)
✅ Escalabilidad para futuras expansiones

El modelo está listo para soportar análisis de Business Intelligence y generación de reportes y dashboards.
