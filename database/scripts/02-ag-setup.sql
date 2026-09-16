/*  02-ag-setup.sql
    Availability Group between prod1 (primary) and prod2 (secondary).

    Run once prod2 reports healthy:
        docker compose --profile ha up -d prod2
        docker compose --profile ha run --rm ag-setup

*/
:setvar DBNAME agdb
:on error exit
SET NOCOUNT ON;
GO

---------------------------------------------------------------- prod1: cert
:CONNECT prod1 -U sa -P $(SAPW)
USE master;
GO

IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = '$(SAPW)';
GO
IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = 'prod1_hadr_cert')
    CREATE CERTIFICATE prod1_hadr_cert WITH SUBJECT = 'prod1 HADR endpoint cert';
GO
DECLARE @exists1 TABLE (file_exists bit, file_is_directory bit, parent_directory_exists bit);
INSERT INTO @exists1 EXEC master.dbo.xp_fileexist '/var/opt/mssql/ag-certs/prod1_hadr_cert.cer';
IF NOT EXISTS (SELECT 1 FROM @exists1 WHERE file_exists = 1)
    BACKUP CERTIFICATE prod1_hadr_cert TO FILE = '/var/opt/mssql/ag-certs/prod1_hadr_cert.cer';
GO

---------------------------------------------------------------- prod2: cert
:CONNECT prod2 -U sa -P $(SAPW)
USE master;
GO

IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = '$(SAPW)';
GO
IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = 'prod2_hadr_cert')
    CREATE CERTIFICATE prod2_hadr_cert WITH SUBJECT = 'prod2 HADR endpoint cert';
GO
DECLARE @exists2 TABLE (file_exists bit, file_is_directory bit, parent_directory_exists bit);
INSERT INTO @exists2 EXEC master.dbo.xp_fileexist '/var/opt/mssql/ag-certs/prod2_hadr_cert.cer';
IF NOT EXISTS (SELECT 1 FROM @exists2 WHERE file_exists = 1)
    BACKUP CERTIFICATE prod2_hadr_cert TO FILE = '/var/opt/mssql/ag-certs/prod2_hadr_cert.cer';
GO

---------------------------------------------------- prod2: trust prod1, endpoint
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'hadr_login')
    CREATE LOGIN hadr_login WITH PASSWORD = 'Ag_HADR_Internal_Login_2025!';
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'hadr_login')
    CREATE USER hadr_login FOR LOGIN hadr_login;
GO
IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = 'prod1_hadr_cert')
    CREATE CERTIFICATE prod1_hadr_cert AUTHORIZATION hadr_login
        FROM FILE = '/var/opt/mssql/ag-certs/prod1_hadr_cert.cer';
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_mirroring_endpoints WHERE name = 'hadr_endpoint')
    CREATE ENDPOINT hadr_endpoint
        STATE = STARTED
        AS TCP (LISTENER_PORT = 5022)
        FOR DATABASE_MIRRORING (
            AUTHENTICATION = CERTIFICATE prod2_hadr_cert,
            ENCRYPTION = REQUIRED ALGORITHM AES,
            ROLE = ALL
        );
GO
GRANT CONNECT ON ENDPOINT::hadr_endpoint TO hadr_login;
GO

---------------------------------------------------- prod1: trust prod2, endpoint
:CONNECT prod1 -U sa -P $(SAPW)
USE master;
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'hadr_login')
    CREATE LOGIN hadr_login WITH PASSWORD = 'Ag_HADR_Internal_Login_2025!';
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'hadr_login')
    CREATE USER hadr_login FOR LOGIN hadr_login;
GO
IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = 'prod2_hadr_cert')
    CREATE CERTIFICATE prod2_hadr_cert AUTHORIZATION hadr_login
        FROM FILE = '/var/opt/mssql/ag-certs/prod2_hadr_cert.cer';
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_mirroring_endpoints WHERE name = 'hadr_endpoint')
    CREATE ENDPOINT hadr_endpoint
        STATE = STARTED
        AS TCP (LISTENER_PORT = 5022)
        FOR DATABASE_MIRRORING (
            AUTHENTICATION = CERTIFICATE prod1_hadr_cert,
            ENCRYPTION = REQUIRED ALGORITHM AES,
            ROLE = ALL
        );
GO
GRANT CONNECT ON ENDPOINT::hadr_endpoint TO hadr_login;
GO

-------------------------------------------------------- prod1: demo db + AG
DECLARE @qagdb sysname = QUOTENAME(N'$(DBNAME)');
IF DB_ID('$(DBNAME)') IS NULL
BEGIN
    EXEC ('CREATE DATABASE ' + @qagdb);
    EXEC ('ALTER DATABASE ' + @qagdb + ' SET RECOVERY FULL');
END
EXEC ('BACKUP DATABASE ' + @qagdb
    + ' TO DISK = ''/var/opt/mssql/data/$(DBNAME)_ag-seed.bak'' WITH INIT');
GO

IF NOT EXISTS (SELECT 1 FROM sys.availability_groups WHERE name = 'ag1')
CREATE AVAILABILITY GROUP [ag1]
    WITH (CLUSTER_TYPE = NONE)
    FOR DATABASE [$(DBNAME)]
    REPLICA ON
        N'prod1' WITH (
            ENDPOINT_URL = N'TCP://prod1:5022',
            AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
            FAILOVER_MODE = MANUAL,
            SEEDING_MODE = AUTOMATIC),
        N'prod2' WITH (
            ENDPOINT_URL = N'TCP://prod2:5022',
            AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
            FAILOVER_MODE = MANUAL,
            SEEDING_MODE = AUTOMATIC);
GO
ALTER AVAILABILITY GROUP [ag1] GRANT CREATE ANY DATABASE;
GO

-------------------------------------------------------- prod2: join + seed perm
:CONNECT prod2 -U sa -P $(SAPW)

IF NOT EXISTS (SELECT 1 FROM sys.availability_groups WHERE name = 'ag1')
    ALTER AVAILABILITY GROUP [ag1] JOIN WITH (CLUSTER_TYPE = NONE);
GO
ALTER AVAILABILITY GROUP [ag1] GRANT CREATE ANY DATABASE;
GO

PRINT 'AG setup complete. Automatic seeding of $(DBNAME) onto prod2 runs in the background — check sys.dm_hadr_database_replica_states for SYNCHRONIZED.';
GO
