----------3.5 Task 5 — Transaction Management and Concurrency-------------

--------------5.1 Explicit Transactions with Error Handling-----------
USE UniHospital ;
Go

-- Declare input variables 

DECLARE @PatientID INT = 1;
DECLARE @NewWardID INT = 2;
DECLARE @OldWardID INT = 1;


-- Transaction: Transfer Patient

BEGIN TRY

    BEGIN TRANSACTION TransferPatient;

    -- Step 1: Discharge current admission
    UPDATE Admission
    SET DischargeDate = CAST(GETDATE() AS DATE)
    WHERE PatientID = @PatientID
      AND DischargeDate IS NULL;

    IF @@ROWCOUNT = 0
        THROW 50010, 'No active admission found for patient.', 1;

    -- Step 2: Admit to new ward
    INSERT INTO Admission (PatientID, WardID, AdmitDate)
    VALUES (@PatientID, @NewWardID, GETDATE());

    -- Step 3: Log transfer
    INSERT INTO TransferLog (PatientID, FromWardID, ToWardID, TransferDate)
    VALUES (@PatientID, @OldWardID, @NewWardID, GETDATE());

    COMMIT TRANSACTION TransferPatient;

END TRY

BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION TransferPatient;

    SELECT
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_SEVERITY() AS Severity,
        ERROR_STATE() AS State,
        ERROR_PROCEDURE() AS ProcedureName,
        ERROR_LINE() AS ErrorLine,
        ERROR_MESSAGE() AS ErrorMessage;

END CATCH;

GO


--------------5.2 Isolation Levels and Deadlock Demonstration---------
------ code to capture deadlock info):

DBCC TRACEON (1222, -1);
DBCC TRACEON (1204, -1);


-- SESSION A: Locks Patient first, then Bill
-- This creates one side of the deadlock


BEGIN TRAN;

-- STEP 1: Lock Patient table first
-- This places a lock on Patient record ID = 1
UPDATE Patient
SET FirstName = FirstName
WHERE PatientID = 1;

-- Explanation:
-- Session A is now holding a lock on Patient table

-- Wait to allow Session B to lock Bill table
WAITFOR DELAY '00:00:05';

-- STEP 2: Try to lock Bill table
-- This will wait because Session B will lock Bill first

UPDATE Bill
SET TotalAmount = TotalAmount
WHERE PatientID = 1;

-- If no deadlock, transaction completes here
COMMIT TRAN;

-- Explanation:
-- This session now waits for Bill lock held by Session B


-- SESSION B: Locks Bill first, then Patient
-- Opposite order creates deadlock condition


BEGIN TRAN;

-- STEP 1: Lock Bill table first
UPDATE Bill
SET TotalAmount = TotalAmount
WHERE PatientID = 1;

-- Explanation:
-- Session B is now holding a lock on Bill table

-- Wait to create overlap with Session A
WAITFOR DELAY '00:00:05';

-- STEP 2: Try to lock Patient table
-- This will be blocked by Session A

UPDATE Patient
SET FirstName = FirstName
WHERE PatientID = 1;

-- Commit (may not reach due to deadlock)
COMMIT TRAN;

-- Explanation:
-- Session B now waits for Patient lock held by Session A


ALTER DATABASE UniHospital
SET READ_COMMITTED_SNAPSHOT ON;

----Resolve the deadlock by (i) enforcing a consistent lock order and (ii) enabling
------READ_COMMITTED_SNAPSHOT isolation.


-- =========================================================
-- 5.2 (B) Solution 1: Enforce consistent lock order
-- Rule: ALWAYS update Patient first, then Bill
-- =========================================================

BEGIN TRAN;

-- STEP 1: Always lock Patient first
UPDATE Patient
SET FirstName = FirstName
WHERE PatientID = 1;

-- STEP 2: Then lock Bill
UPDATE Bill
SET TotalAmount = TotalAmount
WHERE PatientID = 1;

COMMIT TRAN;

