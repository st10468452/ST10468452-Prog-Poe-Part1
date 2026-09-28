============================================================================
-- Module: PROG6212 (Programming 2B)
-- Portfolio of Evidence - Part 1
-- Database: RaceDayDB
-- ============================================================================

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'RaceDayDB')
BEGIN
    CREATE DATABASE RaceDayDB;
END
GO

USE RaceDayDB;
GO

-- Drop tables in reverse dependency order (safe re-runs)
IF OBJECT_ID('Results', 'U') IS NOT NULL DROP TABLE Results;
IF OBJECT_ID('Enrolments', 'U') IS NOT NULL DROP TABLE Enrolments;
IF OBJECT_ID('Categories', 'U') IS NOT NULL DROP TABLE Categories;
IF OBJECT_ID('Events', 'U') IS NOT NULL DROP TABLE Events;
IF OBJECT_ID('Users', 'U') IS NOT NULL DROP TABLE Users;
IF OBJECT_ID('Roles', 'U') IS NOT NULL DROP TABLE Roles;
GO

-- 1. Roles
CREATE TABLE Roles (
    RoleId   INT IDENTITY(1,1) PRIMARY KEY,
    RoleName VARCHAR(50) NOT NULL UNIQUE
);

-- 2. Users
CREATE TABLE Users (
    UserId            INT IDENTITY(1,1) PRIMARY KEY,
    RoleId            INT NOT NULL,
    FullName          VARCHAR(100) NOT NULL,
    Email             VARCHAR(150) NOT NULL UNIQUE,
    PasswordHash      VARCHAR(255) NOT NULL,
    ProfilePictureUrl VARCHAR(255) NULL,
    CreatedAt         DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Users_Roles FOREIGN KEY (RoleId) REFERENCES Roles(RoleId)
);

-- 3. Events
CREATE TABLE Events (
    EventId     INT IDENTITY(1,1) PRIMARY KEY,
    OrganiserId INT NOT NULL,
    Name        VARCHAR(150) NOT NULL,
    Description VARCHAR(MAX) NOT NULL,
    EventDate   DATETIME NOT NULL,
    Location    VARCHAR(200) NOT NULL,
    DistanceKm  DECIMAL(5,2) NOT NULL CHECK (DistanceKm > 0),
    Type        VARCHAR(20) NOT NULL CHECK (Type IN ('Run', 'Walk', 'Cycle')),
    BannerUrl   VARCHAR(255) NULL,
    CONSTRAINT FK_Events_Users FOREIGN KEY (OrganiserId) REFERENCES Users(UserId)
);

-- 4. Categories
CREATE TABLE Categories (
    CategoryId  INT IDENTITY(1,1) PRIMARY KEY,
    EventId     INT NOT NULL,
    Name        VARCHAR(100) NOT NULL,
    DistanceKm  DECIMAL(5,2) NOT NULL CHECK (DistanceKm > 0),
    MaxCapacity INT NOT NULL CHECK (MaxCapacity > 0),
    Fee         DECIMAL(10,2) NOT NULL CHECK (Fee >= 0),
    CONSTRAINT FK_Categories_Events FOREIGN KEY (EventId) REFERENCES Events(EventId) ON DELETE CASCADE
);

-- 5. Enrolments
-- UQ_Participant_Category stops a participant entering the same category twice.
-- A participant MAY enter two different categories of one event (deliberate; see README).
CREATE TABLE Enrolments (
    EnrolmentId   INT IDENTITY(1,1) PRIMARY KEY,
    ParticipantId INT NOT NULL,
    CategoryId    INT NOT NULL,
    EnrolmentDate DATETIME NOT NULL DEFAULT GETDATE(),
    Status        VARCHAR(20) NOT NULL DEFAULT 'Pending'
                  CHECK (Status IN ('Pending', 'Confirmed', 'Cancelled')),
    CONSTRAINT FK_Enrolments_Users      FOREIGN KEY (ParticipantId) REFERENCES Users(UserId),
    CONSTRAINT FK_Enrolments_Categories FOREIGN KEY (CategoryId)    REFERENCES Categories(CategoryId) ON DELETE CASCADE,
    CONSTRAINT UQ_Participant_Category  UNIQUE (ParticipantId, CategoryId)
);

-- 6. Results (optional 0..1 per enrolment)
CREATE TABLE Results (
    ResultId          INT IDENTITY(1,1) PRIMARY KEY,
    EnrolmentId       INT NOT NULL UNIQUE,
    FinishTimeSeconds INT NOT NULL CHECK (FinishTimeSeconds > 0),
    Position          INT NOT NULL CHECK (Position > 0),
    CONSTRAINT FK_Results_Enrolments FOREIGN KEY (EnrolmentId) REFERENCES Enrolments(EnrolmentId) ON DELETE CASCADE
);
GO

-- ============================================================================
-- Seed Data (today = late Sept 2026: Event 1 is past, Events 2-4 are upcoming)
-- ============================================================================

INSERT INTO Roles (RoleName) VALUES ('Organiser'), ('Participant');

-- NOTE: hashes are mock placeholders, so these seeded users cannot log in.
-- Register real users through the API in Part 2.
INSERT INTO Users (RoleId, FullName, Email, PasswordHash) VALUES
(1, 'Sipho Dlamini',   'sipho@raceday.co.za',       'AQAAAAEAACcQAAAAEHmockHashOrganiser1='),
(1, 'Anika Van Der Merwe', 'anika@raceday.co.za',   'AQAAAAEAACcQAAAAEHmockHashOrganiser2='),
(2, 'Thabo Mokoena',   'thabo.mokoena@gmail.com',   'AQAAAAEAACcQAAAAEHmockHashParticipant1='),
(2, 'Sarah Jenkins',   'sarah.jenkins@yahoo.com',   'AQAAAAEAACcQAAAAEHmockHashParticipant2=');

INSERT INTO Events (OrganiserId, Name, Description, EventDate, Location, DistanceKm, Type, BannerUrl) VALUES
(1, 'Two Oceans Marathon 2026', 'The world''s most beautiful marathon around the Cape Peninsula.', '2026-04-04 06:30:00', 'Newlands, Cape Town', 56.00, 'Run',   NULL),
(1, 'Soweto Marathon 2026',     'The People''s Race through historic Soweto.',                    '2026-11-01 05:30:00', 'FNB Stadium, Johannesburg', 42.20, 'Run',   NULL),
(2, 'Cape Town Cycle Tour 2027','The iconic ride around the Cape Peninsula.',                     '2027-03-14 06:00:00', 'Cape Town City Centre', 109.00, 'Cycle', NULL),
(2, 'Joburg Charity Walk 2026', 'A community charity walk through Delta Park.',                   '2026-10-25 08:00:00', 'Delta Park, Johannesburg', 10.00, 'Walk',  NULL);

INSERT INTO Categories (EventId, Name, DistanceKm, MaxCapacity, Fee) VALUES
(1, 'Ultra Marathon',        56.00, 12000, 950.00),   -- CategoryId 1
(1, 'Half Marathon',         21.10, 10000, 450.00),   -- 2
(2, 'Full Marathon',         42.20,  8000, 380.00),   -- 3
(2, 'Half Marathon',         21.10,  8000, 280.00),   -- 4
(2, '10km Fun Run',          10.00,  5000, 180.00),   -- 5
(3, 'Classic 109km',        109.00, 35000, 850.00),   -- 6
(3, 'Family Ride 47km',      47.00,  5000, 450.00),   -- 7
(4, '5km Walk',               5.00,  1500,  50.00),   -- 8
(4, '10km Walk',             10.00,  1500,  80.00);   -- 9

INSERT INTO Enrolments (ParticipantId, CategoryId, Status) VALUES
(3, 1, 'Confirmed'),   -- 1: Thabo, Two Oceans Ultra
(4, 2, 'Confirmed'),   -- 2: Sarah, Two Oceans Half
(3, 3, 'Confirmed'),   -- 3: Thabo, Soweto Full
(4, 5, 'Pending'),     -- 4: Sarah, Soweto 10km
(4, 6, 'Confirmed'),   -- 5: Sarah, Cycle Tour Classic
(3, 8, 'Pending');     -- 6: Thabo, Charity 5km Walk

-- Results only for the completed event (Two Oceans)
INSERT INTO Results (EnrolmentId, FinishTimeSeconds, Position) VALUES
(1, 21540, 812),    -- 5:59:00
(2,  7620, 1893);   -- 2:07:00
GO

-- Verification
SELECT 'Roles' AS Entity, COUNT(*) AS RecordCount FROM Roles
UNION ALL SELECT 'Users', COUNT(*) FROM Users
UNION ALL SELECT 'Events', COUNT(*) FROM Events
UNION ALL SELECT 'Categories', COUNT(*) FROM Categories
UNION ALL SELECT 'Enrolments', COUNT(*) FROM Enrolments
UNION ALL SELECT 'Results', COUNT(*) FROM Results;
GO