
USE master;
GO


-- STEP 1: Set Recovery Model to FULL

ALTER DATABASE UniHospital
SET RECOVERY FULL;
GO

-- STEP 2: FULL DATABASE BACKUP

BACKUP DATABASE UniHospital
TO DISK = 'C:\Backups\UniHospitalFull.bak'
WITH FORMAT,
     INIT,
     CHECKSUM,
     STATS = 10;
GO


---- STEP 3: DIFFERENTIAL BACKUP

BACKUP DATABASE UniHospital
TO DISK = 'C:\Backups\UniHospitalDiff.bak'
WITH DIFFERENTIAL,
     STATS = 10;
GO

--  TRANSACTION LOG BACKUP

BACKUP LOG UniHospital
TO DISK = 'C:\Backups\UniHospitalLog.bak'
WITH STATS = 10;
GO

-- TODO : Write a point -in - time restore to 10 minutes ago.
-- Hint : RESTORE DATABASE ... WITH STOPAT

-- STEP 1: Force all users out of the database

ALTER DATABASE UniHospital
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE;
GO

-- STEP 2: Restore FULL BACKUP (CLEAN BASE RESTORE)

RESTORE DATABASE UniHospital
FROM DISK = 'C:\Backups\UniHospitalFull.bak'
WITH REPLACE,
     RECOVERY;
GO

-- Return database to MULTI-USER mode

ALTER DATABASE UniHospital
SET MULTI_USER;
GO

------------6.2 Security and Roles---------------
USE UniHospital ;
 GO

 -- Create application roles
CREATE ROLE db_clinician ;
CREATE ROLE db_billing ;
CREATE ROLE db_readonly ;

-- Grant appropriate permissions
GRANT SELECT , INSERT , UPDATE
ON Appointment TO db_clinician ;
GRANT SELECT , INSERT , UPDATE
ON Prescription TO db_clinician ;

GRANT SELECT , INSERT , UPDATE
ON Bill TO db_billing ;

GRANT SELECT ON SCHEMA :: dbo TO db_readonly ;

-- TODO : Create a login , a database user , assign to db_clinician role ,
-- and verify they CANNOT access the Bill table .


USE master;
GO


-- TO CREATE LOGIN (SERVER LEVEL)

CREATE LOGIN ClinicianLogin
WITH PASSWORD = 'StrongPassword@123';
GO


-- TO CREATE USER (DATABASE LEVEL)

USE UniHospital;
GO

CREATE USER ClinicianUser
FOR LOGIN ClinicianLogin;
GO

-- TO CREATE ROLE (if not already existing)

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'db_clinician')
BEGIN
    CREATE ROLE db_clinician;
END
GO

-- TO ADD USER TO ROLE

ALTER ROLE db_clinician
ADD MEMBER ClinicianUser;
GO


-- TO GRANT GENERAL ACCESS (EXAMPLE)

GRANT SELECT ON dbo.Appointment TO db_clinician;
GRANT SELECT ON dbo.Prescription TO db_clinician;
GO


--  REVOKE / DENY ACCESS TO BILL TABLE

DENY SELECT ON dbo.Bill TO db_clinician;
GO

-- TODO : Implement row - level security so that doctors can only
-- SELECT their own appointments .


USE UniHospital;
GO

-- STEP 1: CREATE PREDICATE FUNCTION

-- This function checks if the logged-in DoctorID matches the row DoctorID

CREATE OR ALTER FUNCTION dbo.fn_DoctorAccess(@DoctorID INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
(
    SELECT 1 AS access_result
    WHERE @DoctorID = CAST(SESSION_CONTEXT(N'DoctorID') AS INT)
);
GO

-- TO CREATE SECURITY POLICY

-- Apply the filter to Appointment table

CREATE SECURITY POLICY dbo.AppointmentSecurityPolicy
ADD FILTER PREDICATE dbo.fn_DoctorAccess(DoctorID)
ON dbo.Appointment
WITH (STATE = ON);
GO


-- SET SESSION CONTEXT (SIMULATE LOGIN)

-- This represents Doctor ID after login

EXEC sp_set_session_context
    @key = N'DoctorID',
    @value = 1;   -- change for different doctors
GO


-- TO TEST THE SECURITY FILTER

SELECT *
FROM dbo.Appointment;
GO

-----------6.3 Monitoring and Maintenance--------
-- Index fragmentation report
SELECT
OBJECT_NAME (ips . object_id ) AS TableName ,
i. name AS IndexName ,
ips . index_type_desc ,
ROUND (ips . avg_fragmentation_in_percent , 2) AS FragPct ,
ips . page_count
FROM sys . dm_db_index_physical_stats (
DB_ID ('UniHospital '), NULL , NULL , NULL , 'SAMPLED ') ips
JOIN sys . indexes i
ON ips . object_id = i. object_id
AND ips . index_id = i. index_id
WHERE ips . page_count > 100
ORDER BY ips . avg_fragmentation_in_percent DESC ;
GO

-- TODO : Write a maintenance script that :
-- (a) REORGANISEs indexes with 10 -30% fragmentation

USE UniHospital;
GO

DECLARE @TableName NVARCHAR(255);
DECLARE @IndexName NVARCHAR(255);
DECLARE @Fragmentation FLOAT;
DECLARE @SQL NVARCHAR(MAX);

DECLARE index_cursor CURSOR FOR
SELECT 
    t.name AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
JOIN sys.tables t ON ips.object_id = t.object_id
JOIN sys.indexes i ON ips.object_id = i.object_id 
                  AND ips.index_id = i.index_id
WHERE i.name IS NOT NULL
AND ips.index_id > 0;

OPEN index_cursor;

FETCH NEXT FROM index_cursor 
INTO @TableName, @IndexName, @Fragmentation;

WHILE @@FETCH_STATUS = 0
BEGIN

    -- =====================================================
    -- REORGANISE INDEXES (10% - 30%)
    -- =====================================================
    IF @Fragmentation >= 10 AND @Fragmentation <= 30
    BEGIN
        SET @SQL = 'ALTER INDEX [' + @IndexName + '] 
                    ON [' + @TableName + '] 
                    REORGANIZE;';
        EXEC sp_executesql @SQL;
    END

    FETCH NEXT FROM index_cursor 
    INTO @TableName, @IndexName, @Fragmentation;
END

CLOSE index_cursor;
DEALLOCATE index_cursor;
GO

-- TODO : Write a maintenance script that :
-- (b) REBUILDs indexes with > 30% fragmentation

USE UniHospital;
GO

DECLARE @TableName NVARCHAR(255);
DECLARE @IndexName NVARCHAR(255);
DECLARE @Fragmentation FLOAT;
DECLARE @SQL NVARCHAR(MAX);

DECLARE index_cursor CURSOR FOR
SELECT 
    t.name AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
JOIN sys.tables t ON ips.object_id = t.object_id
JOIN sys.indexes i ON ips.object_id = i.object_id 
                  AND ips.index_id = i.index_id
WHERE i.name IS NOT NULL
AND ips.index_id > 0;

OPEN index_cursor;

FETCH NEXT FROM index_cursor 
INTO @TableName, @IndexName, @Fragmentation;

WHILE @@FETCH_STATUS = 0
BEGIN

    -- =====================================================
    -- REBUILD INDEXES (> 30%)
    -- =====================================================
    IF @Fragmentation > 30
    BEGIN
        SET @SQL = 'ALTER INDEX [' + @IndexName + '] 
                    ON [' + @TableName + '] 
                    REBUILD;';
        EXEC sp_executesql @SQL;
    END

    FETCH NEXT FROM index_cursor 
    INTO @TableName, @IndexName, @Fragmentation;
END

CLOSE index_cursor;
DEALLOCATE index_cursor;
GO


-- TODO : Write a maintenance script that :
--(c) UPDATEs statistics on all tables

USE UniHospital;
GO

DECLARE @TableName NVARCHAR(255);

DECLARE table_cursor CURSOR FOR
SELECT name 
FROM sys.tables;

OPEN table_cursor;

FETCH NEXT FROM table_cursor INTO @TableName;

WHILE @@FETCH_STATUS = 0
BEGIN

    -- =====================================================
    -- UPDATE STATISTICS FOR EACH TABLE
    -- =====================================================
    EXEC ('UPDATE STATISTICS [' + @TableName + '] WITH FULLSCAN');

    FETCH NEXT FROM table_cursor INTO @TableName;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;
GO

-- TODO : Write a maintenance script that : 
-- (d) Logs the maintenance run to a MaintenanceLog table

USE UniHospital;
GO

-- =========================================================
-- CREATE MAINTENANCE LOG TABLE
-- =========================================================

IF OBJECT_ID('dbo.MaintenanceLog', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.MaintenanceLog
    (
        LogID INT IDENTITY(1,1) PRIMARY KEY,
        ActionName NVARCHAR(100),
        TableName NVARCHAR(255),
        IndexName NVARCHAR(255),
        Fragmentation FLOAT NULL,
        ActionTaken NVARCHAR(50),
        LogDate DATETIME DEFAULT GETDATE()
    );
END
GO


-- =========================================================
-- EXAMPLE: LOG A MAINTENANCE RUN
-- (Use this inside your maintenance scripts)
-- =========================================================

INSERT INTO dbo.MaintenanceLog
(
    ActionName,
    TableName,
    IndexName,
    Fragmentation,
    ActionTaken
)
VALUES
(
    'Maintenance Run',
    NULL,
    NULL,
    NULL,
    'Completed'
);
GO