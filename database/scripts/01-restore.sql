/*  01-restore.sql
    Restore a .bak dropped in ./restore (mounted read-only at
    /var/opt/mssql/restore) onto this instance.

    Invoked by the `seed` profile:
        docker compose --profile seed up seed
    or manually:
        sqlcmd ... -v DBNAME=billing BAKFILE=billing.bak -i /scripts/01-restore.sql
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

DECLARE @db     sysname       = N'$(DBNAME)';
DECLARE @bak    nvarchar(512) = N'/var/opt/mssql/restore/$(BAKFILE)';
DECLARE @data   nvarchar(512) = N'/var/opt/mssql/data/';
DECLARE @sql    nvarchar(max);
DECLARE @qdb    nvarchar(258) = QUOTENAME(@db);

IF OBJECT_ID('tempdb..#filelist') IS NOT NULL DROP TABLE #filelist;

CREATE TABLE #filelist (
    LogicalName          nvarchar(128),
    PhysicalName         nvarchar(260),
    [Type]               char(1),
    FileGroupName        nvarchar(128)  NULL,
    Size                 numeric(20,0),
    MaxSize              numeric(20,0),
    FileId               bigint,
    CreateLSN            numeric(25,0),
    DropLSN              numeric(25,0)  NULL,
    UniqueId             uniqueidentifier,
    ReadOnlyLSN          numeric(25,0)  NULL,
    ReadWriteLSN         numeric(25,0)  NULL,
    BackupSizeInBytes    bigint,
    SourceBlockSize      int,
    FileGroupId          int,
    LogGroupGUID         uniqueidentifier NULL,
    DifferentialBaseLSN  numeric(25,0)  NULL,
    DifferentialBaseGUID uniqueidentifier NULL,
    IsReadOnly           bit,
    IsPresent            bit,
    TDEThumbprint        varbinary(32)  NULL,
    SnapshotUrl          nvarchar(360)  NULL
);

INSERT INTO #filelist
EXEC ('RESTORE FILELISTONLY FROM DISK = ''' + @bak + '''');

SELECT @sql = N'RESTORE DATABASE ' + @qdb
            + N' FROM DISK = ''' + @bak + N''' WITH REPLACE, RECOVERY, STATS = 5'
            + STRING_AGG(
                  N', MOVE ''' + LogicalName + N''' TO ''' + @data + @db + N'_'
                  + CAST(FileId AS nvarchar(10))
                  + CASE [Type] WHEN N'L' THEN N'.ldf' ELSE N'.mdf' END + N'''',
                  N'')
FROM #filelist;

/*  Kick anyone off before REPLACE.  */
IF DB_ID(@db) IS NOT NULL
    EXEC (N'ALTER DATABASE ' + @qdb
        + N' SET SINGLE_USER WITH ROLLBACK IMMEDIATE');

PRINT @sql;
EXEC (@sql);

EXEC (N'ALTER DATABASE ' + @qdb + N' SET MULTI_USER');

/*  170 = SQL Server 2025. Restoring from an older instance keeps the source
    compat level, which silently disables OPPO and the 2025 CE feedback paths. */
EXEC (N'ALTER DATABASE ' + @qdb + N' SET COMPATIBILITY_LEVEL = 170');
EXEC (N'ALTER DATABASE ' + @qdb + N' SET QUERY_STORE = ON');
EXEC (N'ALTER DATABASE ' + @qdb
    + N' SET QUERY_STORE (OPERATION_MODE = READ_WRITE, QUERY_CAPTURE_MODE = ALL)');

GO

/*  Vector indexes / DiskANN are gated behind preview features in 2025 RTM. */
USE $(DBNAME);
GO
ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = ON;
GO
PRINT 'restore complete';
GO
