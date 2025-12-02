-- Crea DB si no existe
IF DB_ID('appdb') IS NULL
BEGIN
  EXEC('CREATE DATABASE appdb');
END
GO

USE appdb;
GO

-- Tablas (idempotente)
IF OBJECT_ID('dbo.customers') IS NULL
BEGIN
  CREATE TABLE dbo.customers(
    id INT IDENTITY PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    email NVARCHAR(200) NOT NULL UNIQUE,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
  );
END

IF OBJECT_ID('dbo.orders') IS NULL
BEGIN
  CREATE TABLE dbo.orders(
    id INT IDENTITY PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES dbo.customers(id),
    total_amount DECIMAL(18,2) NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
  );
END
GO

-- Habilitar CDC a nivel DB
IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name='appdb' AND is_cdc_enabled=1)
BEGIN
  EXEC sys.sp_cdc_enable_db;
END
GO

-- Habilitar CDC por tabla (idempotente)
IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('dbo.customers'))
BEGIN
  EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name   = N'customers',
    @role_name     = NULL,
    @supports_net_changes = 0;
END

IF NOT EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('dbo.orders'))
BEGIN
  EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name   = N'orders',
    @role_name     = NULL,
    @supports_net_changes = 0;
END
GO

-- (Opcional) Asegurar jobs CDC; si ya corren, puede loguear "already running" (benigno)
IF NOT EXISTS (
    SELECT 1
    FROM msdb.dbo.sysjobs sj
    JOIN msdb.dbo.sysjobactivity sja ON sj.job_id = sja.job_id
    WHERE sj.name = 'cdc.appdb_capture'
      AND sja.stop_execution_date IS NULL
)
BEGIN
    EXEC sys.sp_cdc_start_job @job_type='capture';
END;

IF NOT EXISTS (
    SELECT 1
    FROM msdb.dbo.sysjobs sj
    JOIN msdb.dbo.sysjobactivity sja ON sj.job_id = sja.job_id
    WHERE sj.name = 'cdc.appdb_cleanup'
      AND sja.stop_execution_date IS NULL
)
BEGIN
    EXEC sys.sp_cdc_start_job @job_type='cleanup';
END;

GO

-- SEED *solo si* está vacío (dispara snapshot o CDC y fuerza creación de tópicos)
IF NOT EXISTS (SELECT 1 FROM dbo.customers)
BEGIN
  INSERT INTO dbo.customers(name,email) VALUES ('Ada','ada@ex.com'),('Linus','linus@ex.com');
  INSERT INTO dbo.orders(customer_id,total_amount) VALUES (1,100.00),(2,230.50);
END
GO
