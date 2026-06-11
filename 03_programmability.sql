-- Task 3.1(b): usp_DischargePatient
USE UniHospital;
GO

CREATE OR ALTER PROCEDURE usp_DischargePatient
    @AdmissionID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        BEGIN TRANSACTION;

        DECLARE
            @PatientID INT,
            @BillAmount DECIMAL(12,2);

        -- Get patient
        SELECT
            @PatientID = PatientID
        FROM Admission
        WHERE AdmissionID = @AdmissionID;

        -- Update discharge date
        UPDATE Admission
        SET DischargeDate = CAST(GETDATE() AS DATE)
        WHERE AdmissionID = @AdmissionID;

        -- Calculate bill amount
        SELECT
            @BillAmount =
            SUM(
                p.Quantity * m.UnitCost
            )
        FROM Prescription p
        JOIN Medication m
            ON p.MedID = m.MedID
        WHERE p.AdmissionID = @AdmissionID;

        SET @BillAmount =
            ISNULL(@BillAmount,0);

        -- Create bill
        INSERT INTO Bill
        (
            PatientID,
            AdmissionID,
            TotalAmount,
            PaidAmount,
            BillDate,
            Status
        )
        VALUES
        (
            @PatientID,
            @AdmissionID,
            @BillAmount,
            0,
            GETDATE(),
            'Unpaid'
        );

        -- Reduce stock quantity
        UPDATE m
        SET m.StockQty =
            m.StockQty - p.Quantity
        FROM Medication m
        JOIN Prescription p
            ON m.MedID = p.MedID
        WHERE p.AdmissionID = @AdmissionID;

        COMMIT TRANSACTION;

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH
END;
GO

-- Task 3.1(c) usp_DoctorWorkloadReport
CREATE OR ALTER PROCEDURE usp_DoctorWorkloadReport
(
    @StartDate DATE,
    @EndDate DATE
)
AS
BEGIN

SELECT

    d.DoctorID,
    d.FirstName + ' ' + d.LastName AS DoctorName,

    COUNT(DISTINCT a.AppointmentID)
        AS AppointmentCount,

    COUNT(DISTINCT pr.AdmissionID)
        AS AdmissionCount,

    AVG(
        CAST(
            b.TotalAmount AS DECIMAL(12,2)
        )
    ) AS AverageBillValue

FROM Doctor d

LEFT JOIN Appointment a
    ON d.DoctorID = a.DoctorID
    AND a.ApptDate
        BETWEEN @StartDate
        AND @EndDate

LEFT JOIN Prescription pr
    ON d.DoctorID = pr.DoctorID

LEFT JOIN Bill b
    ON pr.AdmissionID =
       b.AdmissionID

GROUP BY

    d.DoctorID,
    d.FirstName,
    d.LastName

ORDER BY
    AppointmentCount DESC;

END;
GO

-- usp_AdmitPatient
USE UniHospital;
GO

CREATE OR ALTER PROCEDURE usp_AdmitPatient
    @PatientID INT,
    @WardID INT,
    @DiagnosisCode NVARCHAR(20),
    @AdmissionID INT OUTPUT
AS
BEGIN

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        BEGIN TRANSACTION;

        -- Check ward capacity
        DECLARE
            @Capacity INT,
            @CurrentOcc INT;

        SELECT
            @Capacity = Capacity
        FROM Ward
        WHERE WardID = @WardID;

        SELECT
            @CurrentOcc = COUNT(*)
        FROM Admission
        WHERE WardID = @WardID
        AND DischargeDate IS NULL;

        IF @CurrentOcc >= @Capacity
            THROW 50001, 'Ward is at full capacity.',1;

        INSERT INTO Admission
        (
            PatientID,
            WardID,
            DiagnosisCode
        )
        VALUES
        (
            @PatientID,
            @WardID,
            @DiagnosisCode
        );

        SET @AdmissionID = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH

END;
GO


-- Tests
DECLARE @NewAdmissionID INT;

EXEC usp_AdmitPatient
    @PatientID=2,
    @WardID=1,
    @DiagnosisCode='I15',
    @AdmissionID=@NewAdmissionID OUTPUT;

SELECT @NewAdmissionID;
GO


EXEC usp_DoctorWorkloadReport
'2026-01-01',
'2026-12-31';
GO

-- Test
EXEC usp_DoctorWorkloadReport
'2026-01-01',
'2026-12-31';
GO

-- 3.2(a) Patient Age Function
CREATE OR ALTER FUNCTION dbo.fn_PatientAge
(
    @DOB DATE
)
RETURNS INT
AS
BEGIN

RETURN
    DATEDIFF(YEAR,@DOB,GETDATE())
    -
    CASE
        WHEN FORMAT(GETDATE(),'MMdd')
             < FORMAT(@DOB,'MMdd')
        THEN 1
        ELSE 0
    END;

END;
GO

-- 3.2(b) Inline Table-Valued Function — fn_PatientHistory
-- Returns:
-- Appointments
-- Admissions
-- Prescriptions
-- Bills
-- Chronological order
CREATE OR ALTER FUNCTION dbo.fn_PatientHistory
(
    @PatientID INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        'Appointment' AS RecordType,
        a.ApptDate AS EventDate,
        a.Status AS Details
    FROM Appointment a
    WHERE a.PatientID=@PatientID

    UNION ALL

    SELECT
        'Admission',
        ad.AdmitDate,
        ad.DiagnosisCode
    FROM Admission ad
    WHERE ad.PatientID=@PatientID

    UNION ALL

    SELECT
        'Prescription',
        p.PrescDate,
        m.MedName
    FROM Prescription p
    JOIN Admission ad
        ON p.AdmissionID=ad.AdmissionID
    JOIN Medication m
        ON p.MedID=m.MedID
    WHERE ad.PatientID=@PatientID

    UNION ALL

    SELECT
        'Bill',
        b.BillDate,
        CAST(b.TotalAmount AS NVARCHAR(50))
    FROM Bill b
    WHERE b.PatientID=@PatientID
);
GO

-- 3.2(c) Outstanding Balance Function
CREATE OR ALTER FUNCTION dbo.fn_OutstandingBalance
(
    @PatientID INT
)
RETURNS DECIMAL(12,2)
AS
BEGIN

DECLARE @Outstanding DECIMAL(12,2);

SELECT
    @Outstanding=
    SUM(
        TotalAmount-PaidAmount
    )
FROM Bill
WHERE PatientID=@PatientID;

RETURN ISNULL(@Outstanding,0);

END;
GO

-- Function Tests
-- Test age function
SELECT
    PatientID,
    FirstName,
    LastName,
    dbo.fn_PatientAge(DOB) AS Age
FROM Patient;
GO


-- Test patient history
SELECT *
FROM dbo.fn_PatientHistory(1)
ORDER BY EventDate;
GO


-- Test outstanding balance
SELECT
    PatientID,
    FirstName,
    LastName,
    dbo.fn_OutstandingBalance(PatientID)
    AS OutstandingBalance
FROM Patient;
GO

-- Task 3.3 - Triggers
-- 3.3(a) Audit Trigger on Patient
-- Audit Table
CREATE TABLE PatientAuditLog
(
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    Action NVARCHAR(10) NOT NULL,
    PatientID INT,
    ChangedBy NVARCHAR(100)
        DEFAULT SYSTEM_USER,
    ChangedAt DATETIME2
        DEFAULT SYSDATETIME(),
    OldData NVARCHAR(MAX),
    NewData NVARCHAR(MAX)
);
GO


-- Audit Trigger
CREATE OR ALTER TRIGGER trg_Patient_Audit
ON Patient
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT
    INSERT INTO PatientAuditLog
    (
        Action,
        PatientID,
        NewData
    )
    SELECT
        'INSERT',
        i.PatientID,
        (
            SELECT
                i.PatientID,
                i.FirstName,
                i.LastName,
                i.DOB,
                i.Gender,
                i.Address,
                i.Phone,
                i.InsuranceNo
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    FROM inserted i
    LEFT JOIN deleted d
        ON i.PatientID = d.PatientID
    WHERE d.PatientID IS NULL;


    -- DELETE
    INSERT INTO PatientAuditLog
    (
        Action,
        PatientID,
        OldData
    )
    SELECT
        'DELETE',
        d.PatientID,
        (
            SELECT
                d.PatientID,
                d.FirstName,
                d.LastName,
                d.DOB,
                d.Gender,
                d.Address,
                d.Phone,
                d.InsuranceNo
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    FROM deleted d
    LEFT JOIN inserted i
        ON d.PatientID = i.PatientID
    WHERE i.PatientID IS NULL;


    -- UPDATE
    INSERT INTO PatientAuditLog
    (
        Action,
        PatientID,
        OldData,
        NewData
    )
    SELECT
        'UPDATE',
        i.PatientID,
        (
            SELECT
                d.PatientID,
                d.FirstName,
                d.LastName,
                d.DOB,
                d.Gender,
                d.Address,
                d.Phone,
                d.InsuranceNo
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ),
        (
            SELECT
                i.PatientID,
                i.FirstName,
                i.LastName,
                i.DOB,
                i.Gender,
                i.Address,
                i.Phone,
                i.InsuranceNo
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    FROM inserted i
    JOIN deleted d
        ON i.PatientID = d.PatientID;
END;
GO

-- 3.3(b) Create Billing View + INSTEAD OF UPDATE
CREATE VIEW BillingView
AS

SELECT

    p.PatientID,
    p.FirstName,
    p.LastName,

    b.BillID,
    b.TotalAmount,
    b.PaidAmount,
    b.Status

FROM Patient p
JOIN Bill b
ON p.PatientID=b.PatientID;
GO

-- 3.3(c) Doctor appointment limit trigger
CREATE OR ALTER TRIGGER trg_DoctorAppointmentLimit
ON Appointment
AFTER INSERT, UPDATE
AS
BEGIN

SET NOCOUNT ON;

IF EXISTS
(
    SELECT
        DoctorID,
        ApptDate,
        COUNT(*) AS AppointmentCount

    FROM Appointment

    WHERE Status<>'Cancelled'

    GROUP BY
        DoctorID,
        ApptDate

    HAVING COUNT(*) > 10
)

BEGIN

    RAISERROR
    (
        'Doctor cannot have more than 10 active appointments on the same date.',
        16,
        1
    );

    ROLLBACK TRANSACTION;

END

END;
GO

-- Trigger Tests
-- Test audit trigger
UPDATE Patient
SET Phone='077777777'
WHERE PatientID=1;

SELECT *
FROM PatientAuditLog;
GO


-- Test Billing View trigger
UPDATE BillingView
SET PaidAmount=500
WHERE BillID=2;

SELECT *
FROM Bill
WHERE BillID=2;
GO

