-- 2.1(a): List  each  department  with  the  total  number  of  doctors,  average  salary  of  
-- associated staff,  and  the  number  of  current  admissions

USE UniHospital;
GO

SELECT
    d.DeptID,
    d.DeptName,

    COUNT(DISTINCT doc.DoctorID) AS TotalDoctors,

    AVG(CAST(st.Salary AS DECIMAL(10,2))) AS AverageStaffSalary,

    COUNT(DISTINCT adm.AdmissionID) AS CurrentAdmissions

FROM Department d

LEFT JOIN Doctor doc
    ON d.DeptID = doc.DeptID

LEFT JOIN Staff st
    ON d.DeptID = st.DeptID

LEFT JOIN Ward w
    ON d.DeptID = w.DeptID

LEFT JOIN Admission adm
    ON w.WardID = adm.WardID
    AND adm.DischargeDate IS NULL

GROUP BY
    d.DeptID,
    d.DeptName

ORDER BY
    d.DeptName;
GO

-- 2.1(b): Find  patients  who  have  had  more  than  three  appointments  in  the  last  12  months, 
-- ordered  by  appointment  count  descending.
SELECT
    p.PatientID,
    p.FirstName + ' ' + p.LastName AS PatientName,
    COUNT(a.AppointmentID) AS AppointmentCount

FROM Patient p
JOIN Appointment a
    ON p.PatientID = a.PatientID

WHERE
    a.ApptDate >= DATEADD(MONTH,-12,GETDATE())

GROUP BY
    p.PatientID,
    p.FirstName,
    p.LastName

HAVING
    COUNT(a.AppointmentID) > 3

ORDER BY
    AppointmentCount DESC;
GO


-- 2.1(c): Report  total  billed  amount,  total  paid  amount,  and  outstanding  balance  per  patient, 
-- showing  only  patients  with  an  outstanding  balance  greater  than  $500.
SELECT
    p.PatientID,
    p.FirstName + ' ' + p.LastName AS PatientName,

    SUM(b.TotalAmount) AS TotalBilled,

    SUM(b.PaidAmount) AS TotalPaid,

    SUM(b.TotalAmount - b.PaidAmount)
        AS OutstandingBalance

FROM Patient p
JOIN Bill b
    ON p.PatientID = b.PatientID

GROUP BY
    p.PatientID,
    p.FirstName,
    p.LastName

HAVING
    SUM(b.TotalAmount - b.PaidAmount) > 500

ORDER BY
    OutstandingBalance DESC;
GO

-- 2.2(a) STARTS HERE
USE UniHospital;
GO

-- 2.2(a): Rank doctors within each department by number of appointments
-- using RANK() and DENSE_RANK().
-- Show both rankings side-by-side.

SELECT
    d.DeptName,
    doc.DoctorID,
    doc.FirstName + ' ' + doc.LastName AS DoctorName,
    COUNT(a.AppointmentID) AS AppointmentCount,

    RANK() OVER (
        PARTITION BY d.DeptID
        ORDER BY COUNT(a.AppointmentID) DESC
    ) AS RankByDept,

    DENSE_RANK() OVER (
        PARTITION BY d.DeptID
        ORDER BY COUNT(a.AppointmentID) DESC
    ) AS DenseRankByDept

FROM Doctor doc
    JOIN Department d
        ON doc.DeptID = d.DeptID
    LEFT JOIN Appointment a
        ON a.DoctorID = doc.DoctorID

GROUP BY
    d.DeptID,
    d.DeptName,
    doc.DoctorID,
    doc.FirstName,
    doc.LastName;

GO

-- 2.2 b: Use      LAG ()      and      LEAD ()      to      show ,      for      each      admission      per patient ,
SELECT
    PatientID,
    AdmissionID,
    AdmitDate,

    LAG(AdmitDate)
        OVER (
            PARTITION BY PatientID
            ORDER BY AdmitDate
        ) AS PreviousAdmission,

    LEAD(AdmitDate)
        OVER (
            PARTITION BY PatientID
            ORDER BY AdmitDate
        ) AS NextAdmission

FROM Admission
ORDER BY
    PatientID,
    AdmitDate;
GO


-- 2.2 c: Compute a 3- month rolling average of total bills issued
-- using      a      window      frame      ( ROWS      BETWEEN      2      PRECEDING      AND  CURRENT      ROW ).
--      TODO :      write      this      query

SELECT
    YEAR(BillDate) AS BillYear,
    MONTH(BillDate) AS BillMonth,
    SUM(TotalAmount) AS MonthlyTotal,

    AVG(
        SUM(TotalAmount)
    ) OVER (
        ORDER BY
            YEAR(BillDate),
            MONTH(BillDate)
        ROWS BETWEEN 2 PRECEDING
        AND CURRENT ROW
    ) AS Rolling3MonthAverage

FROM Bill

GROUP BY
    YEAR(BillDate),
    MONTH(BillDate)

ORDER BY
    BillYear,
    BillMonth;
GO





-- 2.2 d: Use NTILE (4) to segment patients into quartiles
-- based      on      total      lifetime      billed      amount .
--      TODO :      write      this      query

SELECT
    PatientID,
    PatientName,
    TotalLifetimeBill,

    NTILE(4)
    OVER (
        ORDER BY TotalLifetimeBill DESC
    ) AS BillingQuartile

FROM
(
    SELECT
        p.PatientID,
        p.FirstName + ' ' + p.LastName AS PatientName,
        SUM(b.TotalAmount) AS TotalLifetimeBill

    FROM Patient p

    JOIN Bill b
        ON p.PatientID = b.PatientID

    GROUP BY
        p.PatientID,
        p.FirstName,
        p.LastName

) AS PatientBills

ORDER BY
    BillingQuartile,
    TotalLifetimeBill DESC;
GO



-- 2.3(a): Add ParentDeptID for department hierarchy
ALTER TABLE Department
ADD ParentDeptID INT NULL;
GO

ALTER TABLE Department
ADD CONSTRAINT FK_Department_Parent
FOREIGN KEY (ParentDeptID) REFERENCES Department(DeptID);
GO

-- Sample hierarchy
UPDATE Department SET ParentDeptID = 5 WHERE DeptID IN (1, 2, 3, 4);
GO

WITH DepartmentHierarchy AS (
    SELECT
        DeptID,
        DeptName,
        ParentDeptID,
        0 AS HierarchyLevel,
        CAST(DeptName AS NVARCHAR(MAX)) AS HierarchyPath
    FROM Department
    WHERE ParentDeptID IS NULL

    UNION ALL

    SELECT
        d.DeptID,
        d.DeptName,
        d.ParentDeptID,
        dh.HierarchyLevel + 1,
        CAST(dh.HierarchyPath + ' > ' + d.DeptName AS NVARCHAR(MAX))
    FROM Department d
    INNER JOIN DepartmentHierarchy dh
        ON d.ParentDeptID = dh.DeptID
)
SELECT *
FROM DepartmentHierarchy
ORDER BY HierarchyPath;
GO


-- 2.3(b): Readmitted patients within 30 days
WITH AdmissionSequence AS (
    SELECT
        AdmissionID,
        PatientID,
        AdmitDate,
        DischargeDate,
        LAG(DischargeDate) OVER (
            PARTITION BY PatientID
            ORDER BY AdmitDate
        ) AS PreviousDischargeDate
    FROM Admission
)
SELECT
    p.PatientID,
    p.FirstName + ' ' + p.LastName AS PatientName,
    AdmissionID,
    AdmitDate,
    PreviousDischargeDate,
    DATEDIFF(DAY, PreviousDischargeDate, AdmitDate) AS DaysSinceDischarge
FROM AdmissionSequence a
JOIN Patient p
    ON a.PatientID = p.PatientID
WHERE
    PreviousDischargeDate IS NOT NULL
    AND DATEDIFF(DAY, PreviousDischargeDate, AdmitDate) BETWEEN 0 AND 30
ORDER BY
    PatientName,
    AdmitDate;
GO



-- 2.3(c): Top-5 highest-cost medications per department, then global rank
WITH MedicationByDepartment AS (
    SELECT
        d.DeptID,
        d.DeptName,
        m.MedID,
        m.MedName,
        m.UnitCost,
        SUM(pr.Quantity) AS TotalQuantityPrescribed,
        SUM(pr.Quantity * m.UnitCost) AS TotalMedicationCost
    FROM Department d
    JOIN Doctor doc
        ON d.DeptID = doc.DeptID
    JOIN Prescription pr
        ON doc.DoctorID = pr.DoctorID
    JOIN Medication m
        ON pr.MedID = m.MedID
    GROUP BY
        d.DeptID,
        d.DeptName,
        m.MedID,
        m.MedName,
        m.UnitCost
),
DepartmentRanked AS (
    SELECT
        *,
        RANK() OVER (
            PARTITION BY DeptID
            ORDER BY TotalMedicationCost DESC
        ) AS DepartmentMedicationRank
    FROM MedicationByDepartment
),
TopFivePerDepartment AS (
    SELECT *
    FROM DepartmentRanked
    WHERE DepartmentMedicationRank <= 5
)
SELECT
    DeptName,
    MedName,
    UnitCost,
    TotalQuantityPrescribed,
    TotalMedicationCost,
    DepartmentMedicationRank,
    RANK() OVER (
        ORDER BY TotalMedicationCost DESC
    ) AS GlobalMedicationRank
FROM TopFivePerDepartment
ORDER BY
    GlobalMedicationRank,
    DeptName;
GO


-- 2.4(a): Doctors above their department's average appointment count
SELECT
    d.DeptName,
    doc.DoctorID,
    doc.FirstName + ' ' + doc.LastName AS DoctorName,
    COUNT(a.AppointmentID) AS AppointmentCount
FROM Doctor doc
JOIN Department d
    ON doc.DeptID = d.DeptID
LEFT JOIN Appointment a
    ON doc.DoctorID = a.DoctorID
GROUP BY
    d.DeptName,
    doc.DeptID,
    doc.DoctorID,
    doc.FirstName,
    doc.LastName
HAVING COUNT(a.AppointmentID) >
(
    SELECT AVG(CAST(DoctorAppointmentCount AS DECIMAL(10,2)))
    FROM
    (
        SELECT
            doc2.DoctorID,
            COUNT(a2.AppointmentID) AS DoctorAppointmentCount
        FROM Doctor doc2
        LEFT JOIN Appointment a2
            ON doc2.DoctorID = a2.DoctorID
        WHERE doc2.DeptID = doc.DeptID
        GROUP BY doc2.DoctorID
    ) AS DeptDoctorCounts
)
ORDER BY
    d.DeptName,
    AppointmentCount DESC;
GO


-- 2.4(b): Patients admitted but never had an appointment
SELECT
    p.PatientID,
    p.FirstName + ' ' + p.LastName AS PatientName
FROM Patient p
WHERE p.PatientID IN
(
    SELECT PatientID FROM Admission
    EXCEPT
    SELECT PatientID FROM Appointment
)
ORDER BY PatientName;
GO


-- 2.4(c): Staff members who are also patients
SELECT
    FirstName,
    LastName
FROM Staff

INTERSECT

SELECT
    FirstName,
    LastName
FROM Patient;
GO