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
    role_id INT NOT NULL REFERENCES Roles (id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (
        status IN (
            'active',
            'inactive',
            'suspended'
        )
    )
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

ALTER TABLE Classes ADD CONSTRAINT uq_classes UNIQUE (level_id, academic_year_id, name);

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

-- ============================================================
-- FINANCE – Structure révisée
-- ============================================================

-- Types de frais (inchangé, c'est déjà bien)
CREATE TABLE FeeTypes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE, -- "Scolarité", "Inscription", "Cantine"
    description TEXT
);

-- Grille tarifaire : montant total dû par niveau/année/type
-- On supprime payment_schedule_type_id ici — le "comment" est dans FeeInstallments
CREATE TABLE FeeStructures (
    id SERIAL PRIMARY KEY,
    fee_type_id INT NOT NULL REFERENCES FeeTypes (id) ON DELETE RESTRICT,
    level_id INT NOT NULL REFERENCES Levels (id) ON DELETE RESTRICT,
    academic_year_id INT NOT NULL REFERENCES AcademicYears (id) ON DELETE RESTRICT,
    total_amount NUMERIC(12, 2) NOT NULL CHECK (total_amount >= 0),
    description TEXT,
    UNIQUE (
        fee_type_id,
        level_id,
        academic_year_id
    ) -- une seule grille par combinaison
);

-- Échéancier planifié : chaque ligne = une tranche attendue
-- Ex: Scolarité 6ème 2025 → Tranche 1 : 100 000 Ar le 01/10/2025
CREATE TABLE FeeInstallments (
    id SERIAL PRIMARY KEY,
    fee_structure_id INT NOT NULL REFERENCES FeeStructures (id) ON DELETE CASCADE,
    installment_number SMALLINT NOT NULL CHECK (installment_number > 0), -- 1, 2, 3...
    label VARCHAR(100), -- "Tranche 1", "Octobre", "Acompte rentrée"
    amount_due NUMERIC(12, 2) NOT NULL CHECK (amount_due > 0),
    due_date DATE NOT NULL,
    UNIQUE (
        fee_structure_id,
        installment_number
    )
    -- La somme des amount_due devrait = FeeStructures.total_amount (à vérifier côté app)
);

-- Versements réels d'un élève (inchangé dans l'esprit, mais épuré)
CREATE TABLE Payments (
    id SERIAL PRIMARY KEY,
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
    remarks TEXT,
    recorded_by INT REFERENCES Users (id) ON DELETE SET NULL -- qui a saisi
);

ALTER TABLE Payments ADD COLUMN enrollment_id INT REFERENCES Enrollments(id) ON DELETE RESTRICT;

-- Imputation : à quelle(s) échéance(s) ce versement est attribué
-- Permet les paiements partiels ou les paiements qui couvrent plusieurs tranches
CREATE TABLE PaymentAllocations (
    id SERIAL PRIMARY KEY,
    payment_id INT NOT NULL REFERENCES Payments (id) ON DELETE CASCADE,
    fee_installment_id INT NOT NULL REFERENCES FeeInstallments (id) ON DELETE RESTRICT,
    allocated_amount NUMERIC(12, 2) NOT NULL CHECK (allocated_amount > 0),
    UNIQUE (
        payment_id,
        fee_installment_id
    )
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
    class_id INT NOT NULL REFERENCES Classes (id) ON DELETE CASCADE,
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

CREATE INDEX idx_payments_enroll ON Payments (enrollment_id);

CREATE INDEX idx_attendance_enroll ON Attendance (enrollment_id);

CREATE INDEX idx_schedules_class ON Schedules (class_id);

CREATE INDEX idx_assessments_period ON Assessments (academic_period_id);