# Guía de Configuración de Base de Datos

## 📍 Ubicaciones para Configurar la Base de Datos

Esta guía te indica exactamente dónde debes cambiar la configuración de la base de datos para usar tu propia instancia de SQL Server.

---

## 1. Archivo: `SalesAnalysis.Worker/appsettings.json`

**Línea 10:** Cambia la cadena de conexión `DefaultConnection`

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=TU_SERVIDOR_AQUI;Database=BusinessIntelligenceDW;Trusted_Connection=true;TrustServerCertificate=true;"
  }
}
```

**Ejemplo con autenticación SQL Server:**
```json
"DefaultConnection": "Server=TU_SERVIDOR;Database=BusinessIntelligenceDW;User Id=sa;Password=tu_password;TrustServerCertificate=true;"
```

---

## 2. Archivo: `SalesAnalysis.Web/appsettings.json`

**Línea 3:** Cambia la cadena de conexión `DefaultConnection`

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=TU_SERVIDOR_AQUI;Database=BusinessIntelligenceDW;Trusted_Connection=true;TrustServerCertificate=true;"
  }
}
```

---

## 3. Archivo: `SalesAnalysis.Persistence/Services/ComprehensiveEtlService.cs`

**Línea 184:** Cadena de conexión para extraer datos de Customers
```csharp
var customerExtractor = _extractorFactory.CreateDatabaseExtractor(
    "Server=TU_SERVIDOR_AQUI;Database=BusinessIntelligenceDW;Trusted_Connection=true;TrustServerCertificate=true;",
    "SELECT CustomerId, FirstName, LastName, Email, Phone, City, Country FROM dbo.Customers",
    ...
);
```

**Línea 202:** Cadena de conexión para extraer datos de Products
```csharp
var productExtractor = _extractorFactory.CreateDatabaseExtractor(
    "Server=TU_SERVIDOR_AQUI;Database=BusinessIntelligenceDW;Trusted_Connection=true;TrustServerCertificate=true;",
    "SELECT ProductId, ProductName, Category, Price, Stock FROM dbo.Products",
    ...
);
```

---

## 🔧 Pasos para Configurar

1. **Crea la base de datos en SQL Server:**
   ```sql
   CREATE DATABASE BusinessIntelligenceDW;
   ```

2. **Reemplaza `TU_SERVIDOR_AQUI` en los 3 archivos mencionados:**
   - Si es local: `localhost` o `(localdb)\\MSSQLLocalDB`
   - Si es remoto: `nombre_servidor` o `IP:PUERTO`

3. **Si usas autenticación SQL Server:**
   - Cambia `Trusted_Connection=true` por `User Id=tu_usuario;Password=tu_password;`

4. **Ejecuta las migraciones para crear las tablas:**
   ```bash
   cd SalesAnalysis.Persistence
   dotnet ef migrations add InitialCreate --startup-project ../SalesAnalysis.Worker
   dotnet ef database update --startup-project ../SalesAnalysis.Worker
   ```

---

## ✅ Verificación

Después de configurar, ejecuta el proyecto `SalesAnalysis.Worker` y verifica en los logs que se conecta correctamente a tu base de datos.

---

## ⚠️ Notas Importantes

- El nombre de la base de datos por defecto es: **BusinessIntelligenceDW**
- Puedes cambiarlo, pero asegúrate de actualizarlo en los 3 lugares mencionados
- Si usas SQL Server Express LocalDB, usa: `Server=(localdb)\\MSSQLLocalDB;Database=BusinessIntelligenceDW;...`
- Si usas SQL Server en un servidor remoto, asegúrate de que el puerto 1433 esté abierto

