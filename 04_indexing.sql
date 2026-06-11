USE      UniHospital ; 
GO
--      Clustered      index      already      exists      ( PRIMARY      KEY      on      each      table ).
--      Create      non - clustered      covering      indexes      for      common      query      patterns . 
--      Example :      covering      index      for      appointment      lookups      by      patient      and date

CREATE NONCLUSTERED INDEX IX_Appointment_Patient_Date
ON Appointment (PatientID, ApptDate)
INCLUDE (DoctorID, Status);

--      TODO :      Design      and      justify      indexes      for      the      following      queries :
--      4.1 a:      Patients      with      unpaid      bills      ( Bill . Status      =      ’ Unpaid ’)
CREATE NONCLUSTERED INDEX IX_Bill_Unpaid
ON Bill (Status)
INCLUDE
(
    PatientID,
    TotalAmount,
    PaidAmount,
    BillDate
);
GO

--      4.1 b:      Admissions      currently      in      a      specific      ward      ( DischargeDate      IS NULL )
CREATE NONCLUSTERED INDEX IX_Admission_Ward_Active
ON Admission
(
    WardID,
    DischargeDate
)
INCLUDE
(
    PatientID,
    AdmitDate,
    DiagnosisCode
);
GO

--      4.1 c:      Prescriptions      for      a      given      admission      ordered      by      date 
CREATE NONCLUSTERED INDEX IX_Prescription_Admission_Date
ON Prescription
(
    AdmissionID,
    PrescDate
)
INCLUDE
(
    MedID,
    DoctorID,
    Quantity
);
GO

--      4.1 d: Full - textsearch      on      Appointment . Notes      ( use      Full - Text Index )
CREATE FULLTEXT CATALOG FTC_UniHospital
AS DEFAULT;
GO

-- Create Full-Text Index
SELECT name
FROM sys.indexes
WHERE object_id=
OBJECT_ID('Appointment');
GO

CREATE FULLTEXT INDEX ON Appointment
(
    Notes
)
KEY INDEX PK__Appointm__8ECDFCA24D9E2C02;
GO

-- Test Query for full-text search
SELECT *
FROM Appointment
WHERE CONTAINS
(
    Notes,
    'review'
);
GO


-- Task 4.2
SET      STATISTICS      IO      ON ; 
SET      STATISTICS      TIME      ON ;
--      Run      your      query      here
-- Then capture : actual execution plan ( Ctrl +M in SSMS )
-- or      use      sys . dm_exec_query_plan
SELECT *
FROM   sys.dm_exec_cached_plans cp
CROSS APPLY sys.dm_exec_sql_text ( cp . plan_handle ) st 
CROSS APPLY sys.dm_exec_query_plan (cp. plan_handle ) qp 
WHERE st.text LIKE '% UniHospital % ';


-- Query 1 Appointment Lookup
SELECT
    PatientID,
    ApptDate,
    DoctorID,
    Status
FROM Appointment
WHERE PatientID = 1
AND ApptDate >= '2026-01-01';
GO

-- Query 2 Unpaid Bills
SELECT
    PatientID,
    TotalAmount,
    PaidAmount,
    BillDate
FROM Bill
WHERE Status='Unpaid';
GO

-- Query 3 Current Admissions
SELECT
    PatientID,
    AdmitDate,
    DiagnosisCode
FROM Admission
WHERE WardID=1
AND DischargeDate IS NULL;
GO

-- Query 4 Prescription History
SELECT
    MedID,
    DoctorID,
    Quantity,
    PrescDate
FROM Prescription
WHERE AdmissionID=1
ORDER BY PrescDate;
GO

-- Query 5 Full-Text Search
SELECT
    AppointmentID,
    Notes
FROM Appointment
WHERE CONTAINS
(
    Notes,
    'review'
);
GO

-- Task 4.3 Columnstore Index
CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI_Bill_Analytics
ON Bill
(
    BillDate,
    TotalAmount,
    PaidAmount,
    Status,
    PatientID
);
GO

-- Enabling Statistics
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- Analytics Query
SELECT
    YEAR(BillDate) AS BillYear,
    MONTH(BillDate) AS BillMonth,

    COUNT(*) AS BillCount,

    SUM(TotalAmount) AS TotalBilled,

    SUM(PaidAmount) AS TotalPaid,

    SUM(TotalAmount-PaidAmount)
        AS Outstanding

FROM Bill

GROUP BY
    YEAR(BillDate),
    MONTH(BillDate)

ORDER BY
    BillYear,
    BillMonth;
GO