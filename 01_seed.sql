USE UniHospital;
GO

-- 1. Departments
INSERT INTO Department (DeptName, Location)
VALUES
('Cardiology', 'Block A, Floor 2'),
('Neurology', 'Block B, Floor 3'),
('Orthopaedics', 'Block C, Floor 1'),
('Oncology', 'Block D, Floor 4'),
('General Medicine', 'Block A, Floor 1');
GO

-- 2. Doctors
INSERT INTO Doctor (FirstName, LastName, Specialisation, Phone, HireDate, DeptID)
VALUES
('Musa', 'Zain', 'Cardiologist', '088266175', '2018-03-12', 1),
('Zainab', 'Sesay', 'Cardiologist', '0791430771', '2019-06-21', 1),
('Samuel', 'Conteh', 'Neurologist', '076111003', '2017-01-15', 2),
('Fatmata', 'Bangura', 'Neurologist', '076111004', '2020-09-10', 2),
('Mohamed', 'Koroma', 'Orthopaedic Surgeon', '076111005', '2016-11-05', 3),
('Hawa', 'Jalloh', 'Orthopaedic Specialist', '076111006', '2021-02-18', 3),
('Ibrahim', 'Kargbo', 'Oncologist', '076111007', '2015-07-25', 4),
('Mariama', 'Dumbuya', 'Cancer Specialist', '076111008', '2022-04-03', 4),
('Joseph', 'Fofanah', 'General Physician', '076111009', '2014-08-14', 5),
('Sia', 'Mansaray', 'Internal Medicine', '076111010', '2023-01-09', 5);
GO

-- 3. Assign Head Doctors
UPDATE Department SET HeadDoctorID = 1 WHERE DeptID = 1;
UPDATE Department SET HeadDoctorID = 3 WHERE DeptID = 2;
UPDATE Department SET HeadDoctorID = 5 WHERE DeptID = 3;
UPDATE Department SET HeadDoctorID = 7 WHERE DeptID = 4;
UPDATE Department SET HeadDoctorID = 9 WHERE DeptID = 5;
GO

-- 4. Wards
INSERT INTO Ward (WardName, Capacity, DeptID)
VALUES
('Cardiac Ward', 20, 1),
('Neuro Ward', 15, 2),
('Ortho Ward', 18, 3),
('Oncology Ward', 12, 4),
('General Ward', 25, 5);
GO

-- 5. Patients
INSERT INTO Patient (FirstName, LastName, DOB, Gender, Address, Phone, InsuranceNo)
VALUES
('Alhaji', 'Kamara', '1985-04-12', 'M', 'Kissy, Freetown', '077200001', 'INS001'),
('Kadiatu', 'Sesay', '1992-07-20', 'F', 'Bo City', '077200002', 'INS002'),
('Musa', 'Bangura', '1978-11-03', 'M', 'Kenema', '077200003', 'INS003'),
('Aminata', 'Koroma', '2001-01-17', 'F', 'Makeni', '077200004', 'INS004'),
('Ibrahim', 'Jalloh', '1969-05-30', 'M', 'Waterloo', '077200005', 'INS005'),
('Fatmata', 'Kargbo', '1988-09-22', 'F', 'Lumley', '077200006', 'INS006'),
('John', 'Conteh', '1995-12-11', 'M', 'Aberdeen', '077200007', 'INS007'),
('Hawa', 'Mansaray', '1982-03-05', 'F', 'Hill Station', '077200008', 'INS008'),
('Samuel', 'Dumbuya', '1975-08-18', 'M', 'Goderich', '077200009', 'INS009'),
('Mariama', 'Fofanah', '1999-10-09', 'F', 'Calaba Town', '077200010', 'INS010'),
('Patrick', 'Williams', '1990-02-14', 'M', 'Congo Cross', '077200011', 'INS011'),
('Isatu', 'Turay', '1986-06-25', 'F', 'Murray Town', '077200012', 'INS012'),
('Abdul', 'Sankoh', '1972-04-01', 'M', 'Port Loko', '077200013', 'INS013'),
('Zainab', 'Kallon', '2003-09-16', 'F', 'Kono', '077200014', 'INS014'),
('David', 'Gbla', '1994-12-29', 'M', 'Lungi', '077200015', 'INS015'),
('Esther', 'Cole', '1980-07-08', 'F', 'Regent', '077200016', 'INS016'),
('Emmanuel', 'Rogers', '1965-10-13', 'M', 'Wilberforce', '077200017', 'INS017'),
('Fudia', 'Sorie', '1997-05-24', 'F', 'Brookfields', '077200018', 'INS018'),
('Peter', 'Lamin', '1983-11-27', 'M', 'Kingtom', '077200019', 'INS019'),
('Rebecca', 'Bockarie', '1991-01-06', 'F', 'Juba', '077200020', 'INS020');
GO

-- 6. Appointments
INSERT INTO Appointment (PatientID, DoctorID, ApptDate, ApptTime, Status, Notes)
VALUES
(1,1,'2026-01-05','09:00','Completed','Chest pain review'),
(2,2,'2026-01-06','10:00','Completed','Blood pressure follow-up'),
(3,3,'2026-01-07','11:00','Completed','Migraine consultation'),
(4,4,'2026-01-08','12:00','Scheduled','Seizure assessment'),
(5,5,'2026-01-09','13:00','Completed','Fracture review'),
(6,6,'2026-01-10','14:00','Cancelled','Joint pain review'),
(7,7,'2026-01-11','09:30','Completed','Cancer screening'),
(8,8,'2026-01-12','10:30','Completed','Chemotherapy follow-up'),
(9,9,'2026-01-13','11:30','Completed','General check-up'),
(10,10,'2026-01-14','12:30','No-Show','Internal medicine review'),
(11,1,'2026-02-01','09:00','Completed','Heart rhythm check'),
(12,2,'2026-02-02','10:00','Completed','Hypertension review'),
(13,3,'2026-02-03','11:00','Scheduled','Neurology referral'),
(14,4,'2026-02-04','12:00','Completed','Nerve pain consultation'),
(15,5,'2026-02-05','13:00','Completed','Back pain assessment'),
(16,6,'2026-02-06','14:00','Completed','Knee injury review'),
(17,7,'2026-02-07','09:30','Scheduled','Oncology consultation'),
(18,8,'2026-02-08','10:30','Completed','Tumour review'),
(19,9,'2026-02-09','11:30','Completed','Fever and fatigue'),
(20,10,'2026-02-10','12:30','Completed','Diabetes review'),
(1,1,'2026-03-01','09:00','Completed','Second cardiac review'),
(1,2,'2026-03-15','10:00','Completed','Medication follow-up'),
(1,1,'2026-04-01','09:30','Completed','Cardiology review'),
(1,2,'2026-04-18','10:30','Completed','Blood pressure monitoring'),
(2,2,'2026-03-05','11:00','Completed','Cardiology review'),
(3,3,'2026-03-06','12:00','Completed','Neuro follow-up'),
(4,4,'2026-03-07','13:00','Scheduled','Brain scan review'),
(5,5,'2026-03-08','14:00','Completed','Orthopaedic follow-up'),
(6,6,'2026-03-09','15:00','Completed','Joint therapy review'),
(7,7,'2026-03-10','16:00','Scheduled','Oncology review');
GO

-- 7. Admissions
INSERT INTO Admission (PatientID, WardID, AdmitDate, DischargeDate, DiagnosisCode)
VALUES
(1,1,'2026-01-05','2026-01-12','I20'),
(2,1,'2026-01-07',NULL,'I10'),
(3,2,'2026-01-10','2026-01-18','G43'),
(4,2,'2026-01-15',NULL,'G40'),
(5,3,'2026-01-20','2026-01-28','S82'),
(6,3,'2026-01-25',NULL,'M25'),
(7,4,'2026-02-01','2026-02-10','C50'),
(8,4,'2026-02-05',NULL,'C34'),
(9,5,'2026-02-08','2026-02-14','R50'),
(10,5,'2026-02-10',NULL,'E11'),
(11,1,'2026-02-12','2026-02-18','I49'),
(12,1,'2026-02-15',NULL,'I11'),
(13,2,'2026-02-18','2026-02-26','G45'),
(14,2,'2026-02-20',NULL,'G62'),
(15,3,'2026-02-22','2026-03-01','M54');
GO

-- 8. Medications
INSERT INTO Medication (MedName, DosageForm, UnitCost, StockQty)
VALUES
('Paracetamol', 'Tablet', 2.50, 500),
('Amoxicillin', 'Capsule', 5.00, 300),
('Aspirin', 'Tablet', 3.00, 400),
('Metformin', 'Tablet', 4.50, 250),
('Lisinopril', 'Tablet', 6.00, 200),
('Ibuprofen', 'Tablet', 3.50, 350),
('Omeprazole', 'Capsule', 5.50, 280),
('Ceftriaxone', 'Injection', 25.00, 100),
('Morphine', 'Injection', 30.00, 80),
('Insulin', 'Injection', 40.00, 120);
GO

-- 9. Prescriptions
INSERT INTO Prescription (AdmissionID, MedID, DoctorID, Quantity, PrescDate)
VALUES
(1,3,1,20,'2026-01-06'),
(1,5,1,15,'2026-01-07'),
(2,5,2,30,'2026-01-08'),
(3,1,3,20,'2026-01-11'),
(3,6,3,10,'2026-01-12'),
(4,8,4,5,'2026-01-16'),
(5,6,5,25,'2026-01-21'),
(5,9,5,4,'2026-01-22'),
(6,1,6,20,'2026-01-26'),
(7,8,7,8,'2026-02-02'),
(7,9,7,5,'2026-02-03'),
(8,8,8,10,'2026-02-06'),
(9,1,9,15,'2026-02-09'),
(9,2,9,12,'2026-02-10'),
(10,4,10,30,'2026-02-11'),
(10,10,10,6,'2026-02-12'),
(11,3,1,20,'2026-02-13'),
(12,5,2,25,'2026-02-16'),
(13,7,3,10,'2026-02-19'),
(15,6,5,18,'2026-02-23');
GO

-- 10. Bills
INSERT INTO Bill (PatientID, AdmissionID, TotalAmount, PaidAmount, BillDate, Status)
VALUES
(1,1,1200.00,1200.00,'2026-01-12','Paid'),
(2,2,950.00,300.00,'2026-01-15','Partial'),
(3,3,800.00,800.00,'2026-01-18','Paid'),
(4,4,1500.00,500.00,'2026-01-20','Partial'),
(5,5,2200.00,2200.00,'2026-01-28','Paid'),
(6,6,700.00,0.00,'2026-01-29','Unpaid'),
(7,7,3500.00,1500.00,'2026-02-10','Partial'),
(8,8,4000.00,0.00,'2026-02-11','Unpaid'),
(9,9,650.00,650.00,'2026-02-14','Paid'),
(10,10,1100.00,400.00,'2026-02-15','Partial'),
(11,11,900.00,900.00,'2026-02-18','Paid'),
(12,12,1300.00,0.00,'2026-02-19','Unpaid'),
(13,13,1000.00,1000.00,'2026-02-26','Paid'),
(14,14,1250.00,500.00,'2026-02-27','Partial'),
(15,15,1800.00,1800.00,'2026-03-01','Paid');
GO

-- 11. Staff
INSERT INTO Staff (FirstName, LastName, Role, DeptID, Salary, StartDate)
VALUES
('Thomas', 'Kamara', 'Nurse', 1, 4500.00, '2020-01-10'),
('Adama', 'Sesay', 'Receptionist', 1, 3000.00, '2021-03-15'),
('Philip', 'Bangura', 'Nurse', 2, 4600.00, '2019-07-01'),
('Kadie', 'Koroma', 'Lab Assistant', 2, 3500.00, '2022-05-11'),
('Sorie', 'Jalloh', 'Physiotherapist', 3, 4200.00, '2020-09-20'),
('Mabinty', 'Kargbo', 'Nurse', 3, 4400.00, '2021-11-05'),
('Lamin', 'Dumbuya', 'Radiographer', 4, 5000.00, '2018-02-14'),
('Zainab', 'Mansaray', 'Nurse', 4, 4550.00, '2023-01-22'),
('George', 'Fofanah', 'Records Officer', 5, 3200.00, '2020-04-30'),
('Salamatu', 'Conteh', 'Nurse', 5, 4300.00, '2022-08-18');
GO

PRINT 'UniHospital seed data inserted successfully.';
GO