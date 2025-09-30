-- ===========================================
-- SECTION A: DDL & DML
-- ===========================================

-- A1) Create database and use it
CREATE DATABASE HEALTHOUTREACH;
USE HEALTHOUTREACH;

-- Table: DOCTOR
CREATE TABLE DOCTOR
(
    DoctorID CHAR(4) PRIMARY KEY,
    DoctorName VARCHAR(80) NOT NULL,
    Email VARCHAR(120) UNIQUE NULL,  -- NULL allowed
    Speciality VARCHAR(50) NOT NULL,
    Active BIT NOT NULL DEFAULT(1)
);

-- Table: CLINIC
CREATE TABLE CLINIC
(
    ClinicID CHAR(5) PRIMARY KEY,
    ClinicName VARCHAR(80) NOT NULL,
    ClinicAddress VARCHAR(120) NOT NULL
);

-- Table: OUTREACH
CREATE TABLE OUTREACH
(
    DoctorID CHAR(4),
    ClinicID CHAR(5),
    EventDate DATE NOT NULL,
    SeatsAvailable INT NOT NULL CHECK (SeatsAvailable >= 0),
    Status VARCHAR(12) NOT NULL CHECK (Status IN ('Planned','Confirmed','Cancelled')),
    PRIMARY KEY (DoctorID, ClinicID, EventDate),
    FOREIGN KEY (DoctorID) REFERENCES DOCTOR(DoctorID),
    FOREIGN KEY (ClinicID) REFERENCES CLINIC(ClinicID)
);

-- Show created objects and constraints
SELECT name, type_desc
FROM sys.objects
WHERE type IN ('U','PK','F','C','UQ');

-- ===========================================
-- A2) Populate tables
-- ===========================================

-- DOCTOR
INSERT INTO DOCTOR (DoctorID, DoctorName, Email, Speciality, Active) VALUES
('D001','Nomsa Dlamini','nomsa@clinic.org','GP',1),
('D002','Sipho Nkosi','sipho@clinic.org','Pediatrics',1),
('D003','Maya Naidoo','maya@clinic.org','Dermatology',1),
('D004','Henk Cloete','henk@clinic.org','GP',1),
('D005','Sihle Nukani',NULL,'Physiotherapy',1);

SELECT * FROM DOCTOR;

-- CLINIC
INSERT INTO CLINIC (ClinicID, ClinicName, ClinicAddress) VALUES
('CL001','Joburg Community','167 Pert Road, Johannesburg'),
('CL002','Gqeberha Wellness','5 Second Avenue, Gqeberha'),
('CL003','Mkhize Health','33 Bertha Mkhize Street, Durban'),
('CL004','Durban Central','27 Bram Fischer Road, Durban'),
('CL005','Tshwane Family','210 Du Toit Street, Tshwane');

SELECT * FROM CLINIC;

-- OUTREACH
INSERT INTO OUTREACH (DoctorID, ClinicID, EventDate, SeatsAvailable, Status) VALUES
('D002','CL001','2025-10-10',50,'Confirmed'),
('D002','CL004','2025-10-12',30,'Planned'),
('D003','CL005','2025-10-09',15,'Confirmed'),
('D004','CL003','2025-10-11',20,'Confirmed'),
('D004','CL001','2025-10-10',40,'Planned');

SELECT * FROM OUTREACH;

-- ===========================================
-- A3) Alter OUTREACH to add SeatsBooked
-- ===========================================

ALTER TABLE OUTREACH
ADD SeatsBooked INT NOT NULL DEFAULT(0);

ALTER TABLE OUTREACH
ADD CONSTRAINT CHK_SeatsBooked
CHECK (SeatsBooked >= 0 AND SeatsBooked <= SeatsAvailable);

EXEC sp_help 'OUTREACH';

-- ===========================================
-- A4) Update data
-- ===========================================

UPDATE OUTREACH
SET SeatsBooked = 35
WHERE DoctorID = 'D004'
  AND ClinicID = 'CL001'
  AND EventDate = '2025-10-10';

SELECT * FROM OUTREACH
WHERE DoctorID = 'D004'
  AND ClinicID = 'CL001'
  AND EventDate = '2025-10-10';

-- ===========================================
-- SECTION B: Queries
-- ===========================================

-- B1) Unbooked doctors (no outreach)
SELECT DoctorName
FROM DOCTOR
WHERE NOT EXISTS (
    SELECT 1 FROM OUTREACH
    WHERE OUTREACH.DoctorID = DOCTOR.DoctorID
);

-- B2) Seats per doctor (include those with no outreach)
SELECT DOCTOR.DoctorName,
       ISNULL(SUM(OUTREACH.SeatsAvailable),0) AS TotalSeatsAvailable
FROM DOCTOR
LEFT JOIN OUTREACH
    ON DOCTOR.DoctorID = OUTREACH.DoctorID
GROUP BY DOCTOR.DoctorName
ORDER BY DOCTOR.DoctorName;

-- B3) Best clinic for DoctorID = D004 (max SeatsAvailable)
SELECT DOCTOR.DoctorName,
       CLINIC.ClinicName,
       OUTREACH.SeatsAvailable
FROM OUTREACH
JOIN DOCTOR ON OUTREACH.DoctorID = DOCTOR.DoctorID
JOIN CLINIC ON OUTREACH.ClinicID = CLINIC.ClinicID
WHERE OUTREACH.DoctorID = 'D004'
  AND OUTREACH.SeatsAvailable = (
      SELECT MAX(SeatsAvailable)
      FROM OUTREACH
      WHERE DoctorID = 'D004'
  );

-- B4) Booking pressure (FillRate >= 50%)
SELECT DOCTOR.DoctorName,
       OUTREACH.EventDate,
       OUTREACH.SeatsAvailable,
       OUTREACH.SeatsBooked,
       OUTREACH.SeatsBooked * 100.0 / NULLIF(OUTREACH.SeatsAvailable,0) AS FillRate
FROM OUTREACH
JOIN DOCTOR ON OUTREACH.DoctorID = DOCTOR.DoctorID
WHERE OUTREACH.SeatsBooked * 100.0 / NULLIF(OUTREACH.SeatsAvailable,0) >= 50
ORDER BY FillRate DESC;
