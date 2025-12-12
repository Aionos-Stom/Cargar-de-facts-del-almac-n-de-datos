using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SalesAnalysis.Domain.Interfaces;
using SalesAnalysis.Domain.Configuration;

namespace SalesAnalysis.Worker
{
    public class Worker : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<Worker> _logger;
        private readonly CustomerEtlOptions _options;

        public Worker(
            IServiceProvider serviceProvider,
            ILogger<Worker> logger,
            IOptions<CustomerEtlOptions> options)
        {
            _serviceProvider = serviceProvider ?? throw new ArgumentNullException(nameof(serviceProvider));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
            _options = options?.Value ?? throw new ArgumentNullException(nameof(options));
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            var interval = TimeSpan.FromMinutes(_options.RunIntervalMinutes);
            _logger.LogInformation("ETL Worker iniciado. Intervalo de ejecución: {Interval} minutos", interval.TotalMinutes);

            while (!stoppingToken.IsCancellationRequested)
            {
                using var scope = _serviceProvider.CreateScope();
                var comprehensiveEtlService = scope.ServiceProvider.GetRequiredService<IComprehensiveEtlService>();

                try
                {
                    var result = await comprehensiveEtlService.RunCompleteEtlAsync(stoppingToken);
                    _logger.LogInformation("Ciclo ETL completo finalizado. Clientes: {Customers}, Productos: {Products}, Pedidos: {Orders}, Detalles: {OrderDetails}, DimClientes: {DimCustomers}, DimProductos: {DimProducts}, DimFechas: {DimDates}", 
                        result.CustomersProcessed, result.ProductsProcessed, result.OrdersProcessed, result.OrderDetailsProcessed, 
                        result.DimCustomersProcessed, result.DimProductsProcessed, result.DimDatesProcessed);
                }
                catch (OperationCanceledException)
                {
                    _logger.LogWarning("Ciclo ETL cancelado.");
                    throw;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error inesperado durante el ciclo ETL.");
                }

                try
                {
                    await Task.Delay(interval, stoppingToken);
                }
                catch (OperationCanceledException)
                {
                    break;
                }
            }

            _logger.LogInformation("Worker ETL deteniéndose.");
        }
    }
}
