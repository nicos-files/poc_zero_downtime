-- 02-enable-cdc.sql
USE appdb;
GO
-- Habilitar CDC a nivel DB (si no lo está)
IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name='appdb' AND is_cdc_enabled=1)
BEGIN
  EXEC sys.sp_cdc_enable_db;
END
GO

-- Habilitar CDC en dbo.customers (si no lo está)
IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('dbo.customers'))
BEGIN
  EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name   = N'customers',
    @role_name     = NULL,
    @supports_net_changes = 0;
END
GO

-- Habilitar CDC en dbo.orders (si no lo está)
IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('dbo.orders'))
BEGIN
  EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name   = N'orders',
    @role_name     = NULL,
    @supports_net_changes = 0;
END
GO

-- (Opcional) Asegurar que los jobs de CDC estén corriendo
EXEC sys.sp_cdc_stop_job    @job_type='capture';
EXEC sys.sp_cdc_start_job   @job_type='capture';
EXEC sys.sp_cdc_stop_job    @job_type='cleanup';
EXEC sys.sp_cdc_start_job   @job_type='cleanup';
GO
