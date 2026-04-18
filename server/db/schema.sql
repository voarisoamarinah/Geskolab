-- Active: 1745323907898@@127.0.0.1@5432@geskolab
-- ============================================================
--  GESKOLAB – Database Schema
--  PostgreSQL
-- ============================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ------------------------------------------------------------
-- AUTH & PERMISSIONS
-- ------------------------------------------------------------

CREATE TABLE Roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Resources (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Permissions (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (
        status IN (
            'active',
            'inactive',
            'suspended'
        )
    )
);

CREATE TABLE UserRoles (
    user_id INT NOT NULL REFERENCES Users (id) ON DELETE CASCADE,
    role_id INT NOT NULL REFERENCES Roles (id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE RolePermissions (
    role_id INT NOT NULL REFERENCES Roles (id) ON DELETE CASCADE,
    resource_id INT NOT NULL REFERENCES Resources (id) ON DELETE CASCADE,
    permission_id INT NOT NULL REFERENCES Permissions (id) ON DELETE CASCADE,
    PRIMARY KEY (
        role_id,
        resource_id,
        permission_id
    )
);

-- ------------------------------------------------------------
-- ACADEMIC STRUCTURE
-- ------------------------------------------------------------

CREATE TABLE AcademicYears (
    id SERIAL PRIMARY KEY,
    label VARCHAR(50) NOT NULL UNIQUE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT FALSE,
    CHECK (end_date > start_date)
);

CREATE TABLE Levels (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE Classrooms (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    capacity INT NOT NULL CHECK (capacity > 0),
    type VARCHAR(50)
);

CREATE TABLE Classes (
    id SERIAL PRIMARY KEY,
    level_id INT NOT NULL REFERENCES Levels (id) ON DELETE RESTRICT,
    academic_year_id INT NOT NULL REFERENCES AcademicYears (id) ON DELETE RESTRICT,
    name VARCHAR(100) NOT NULL,
    classroom_id INT REFERENCES Classrooms (id) ON DELETE SET NULL
);

CREATE TABLE Subjects (
    id SERIAL PRIMARY KEY,
    title VARCHAR(150) NOT NULL,
    code VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE LevelSubjects (
    level_id INT NOT NULL REFERENCES Levels (id) ON DELETE CASCADE,
    subject_id INT NOT NULL REFERENCES Subjects (id) ON DELETE CASCADE,
    academic_year_id INT NOT NULL REFERENCES AcademicYears (id) ON DELETE CASCADE,
    coefficient NUMERIC(5, 2) NOT NULL DEFAULT 1 CHECK (coefficient > 0),
    PRIMARY KEY (
        level_id,
        subject_id,
        academic_year_id
    )
);

CREATE TABLE AcademicPeriods (
    id SERIAL PRIMARY KEY,
    academic_year_id INT NOT NULL REFERENCES AcademicYears (id) ON DELETE CASCADE,
    label VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_closed BOOLEAN NOT NULL DEFAULT FALSE,
    CHECK (end_date > start_date)
);

-- ------------------------------------------------------------
-- STAFF
-- ------------------------------------------------------------

CREATE TABLE Teachers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    bio TEXT,
    hiring_date DATE,
    specialization VARCHAR(150),
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (
        status IN ('active', 'inactive')
    )
);

CREATE TABLE TeacherAssignments (
    id SERIAL PRIMARY KEY,
    teacher_id INT NOT NULL REFERENCES Teachers (id) ON DELETE CASCADE,
    subject_id INT NOT NULL REFERENCES Subjects (id) ON DELETE CASCADE,
    class_id INT NOT NULL REFERENCES Classes (id) ON DELETE CASCADE,
    academic_year_id INT NOT NULL REFERENCES AcademicYears (id) ON DELETE CASCADE,
    UNIQUE (
        teacher_id,
        subject_id,
        class_id,
        academic_year_id
    )
);

-- ------------------------------------------------------------
-- STUDENTS & PARENTS
-- ------------------------------------------------------------

CREATE TABLE Students (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    matricule VARCHAR(50) NOT NULL UNIQUE,
    date_of_birth DATE,
    gender VARCHAR(10) CHECK (gender IN ('M', 'F', 'other')),
    address TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (
        status IN (
            'active',
            'inactive',
            'transferred',
            'graduated'
        )
    )
);

CREATE TABLE Parents (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    profession VARCHAR(150),
    emergency_contact VARCHAR(30)
);

CREATE TABLE StudentParents (
    student_id INT NOT NULL REFERENCES Students (id) ON DELETE CASCADE,
    parent_id INT NOT NULL REFERENCES Parents (id) ON DELETE CASCADE,
    relationship_type VARCHAR(50) NOT NULL,
    PRIMARY KEY (student_id, parent_id)
);

CREATE TABLE Enrollments (
    id SERIAL PRIMARY KEY,
    student_id INT NOT NULL REFERENCES Students (id) ON DELETE CASCADE,
    class_id INT NOT NULL REFERENCES Classes (id) ON DELETE RESTRICT,
    academic_year_id INT NOT NULL REFERENCES AcademicYears (id) ON DELETE RESTRICT,
    enrollment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    is_repeating BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE (student_id, academic_year_id)
);

-- ------------------------------------------------------------
-- FINANCE
-- ------------------------------------------------------------

CREATE TABLE FeeTypes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE PaymentScheduleTypes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE CHECK (
        name IN (
            'ANNUAL',
            'MONTHLY',
            'TRIMESTRIAL'
        )
    ),
    description TEXT
);

CREATE TABLE FeeStructures (
    id SERIAL PRIMARY KEY,
    fee_type_id INT NOT NULL REFERENCES FeeTypes (id) ON DELETE RESTRICT,
    level_id INT NOT NULL REFERENCES Levels (id) ON DELETE RESTRICT,
    academic_year_id INT NOT NULL REFERENCES AcademicYears (id) ON DELETE RESTRICT,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
    payment_schedule_type_id INT NOT NULL REFERENCES PaymentScheduleTypes (id) ON DELETE RESTRICT,
    description TEXT,
    due_date DATE
);

CREATE TABLE Payments (
    id SERIAL PRIMARY KEY,
    student_id INT NOT NULL REFERENCES Students (id) ON DELETE RESTRICT,
    label VARCHAR(200),
    fee_structure_id INT NOT NULL REFERENCES FeeStructures (id) ON DELETE RESTRICT,
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    amount_paid NUMERIC(12, 2) NOT NULL CHECK (amount_paid > 0),
    payment_method VARCHAR(50) CHECK (
        payment_method IN (
            'cash',
            'bank_transfer',
            'mobile_money',
            'check',
            'other'
        )
    ),
    receipt_number VARCHAR(100) UNIQUE,
    remarks TEXT
);

-- ------------------------------------------------------------
-- ASSESSMENTS & GRADES
-- ------------------------------------------------------------

CREATE TABLE Assessments (
    id SERIAL PRIMARY KEY,
    class_id INT NOT NULL REFERENCES Classes (id) ON DELETE CASCADE,
    subject_id INT NOT NULL REFERENCES Subjects (id) ON DELETE CASCADE,
    teacher_id INT NOT NULL REFERENCES Teachers (id) ON DELETE RESTRICT,
    academic_period_id INT NOT NULL REFERENCES AcademicPeriods (id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    type VARCHAR(50),
    max_score NUMERIC(6, 2) NOT NULL DEFAULT 20 CHECK (max_score > 0),
    weight NUMERIC(5, 2) NOT NULL DEFAULT 1 CHECK (weight > 0),
    assessment_date DATE
);

CREATE TABLE Grades (
    id SERIAL PRIMARY KEY,
    assessment_id INT NOT NULL REFERENCES Assessments (id) ON DELETE CASCADE,
    student_id INT NOT NULL REFERENCES Students (id) ON DELETE CASCADE,
    score NUMERIC(6, 2) CHECK (score >= 0),
    comment TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (assessment_id, student_id)
);

CREATE TABLE FinalExams (
    id SERIAL PRIMARY KEY,
    subject_id INT NOT NULL REFERENCES Subjects (id) ON DELETE CASCADE,
    academic_period_id INT NOT NULL REFERENCES AcademicPeriods (id) ON DELETE CASCADE,
    student_id INT NOT NULL REFERENCES Students (id) ON DELETE CASCADE,
    score NUMERIC(6, 2) CHECK (score >= 0),
    comment TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (
        subject_id,
        academic_period_id,
        student_id
    )
);

-- ------------------------------------------------------------
-- SCHEDULES & ATTENDANCE
-- ------------------------------------------------------------

CREATE TABLE Schedules (
    id SERIAL PRIMARY KEY,
    class_id INT NOT NULL REFERENCES Classes (id) ON DELETE CASCADE,
    subject_id INT NOT NULL REFERENCES Subjects (id) ON DELETE CASCADE,
    teacher_id INT NOT NULL REFERENCES Teachers (id) ON DELETE RESTRICT,
    classroom_id INT NOT NULL REFERENCES Classrooms (id) ON DELETE RESTRICT,
    academic_year_id INT NOT NULL REFERENCES AcademicYears (id) ON DELETE CASCADE,
    day_of_week SMALLINT NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    CHECK (end_time > start_time)
);

CREATE TABLE Attendance (
    id SERIAL PRIMARY KEY,
    enrollment_id INT NOT NULL REFERENCES Enrollments (id) ON DELETE CASCADE,
    schedule_id INT NOT NULL REFERENCES Schedules (id) ON DELETE CASCADE,
    attendance_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'present' CHECK (
        status IN (
            'present',
            'absent',
            'late',
            'excused'
        )
    ),
    UNIQUE (
        enrollment_id,
        schedule_id,
        attendance_date
    )
);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_userroles_user ON UserRoles (user_id);

CREATE INDEX idx_enrollments_student ON Enrollments (student_id);

CREATE INDEX idx_enrollments_class ON Enrollments (class_id);

CREATE INDEX idx_grades_student ON Grades (student_id);

CREATE INDEX idx_grades_assessment ON Grades (assessment_id);

CREATE INDEX idx_payments_student ON Payments (student_id);

CREATE INDEX idx_attendance_enroll ON Attendance (enrollment_id);

CREATE INDEX idx_schedules_class ON Schedules (class_id);

CREATE INDEX idx_assessments_period ON Assessments (academic_period_id);