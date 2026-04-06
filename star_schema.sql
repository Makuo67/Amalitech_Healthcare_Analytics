-- ============================================================
-- STAR SCHEMA FOR HEALTHCARE ANALYTICS
-- ============================================================
-- ============================================================
-- DIMENSION TABLES
-- ============================================================
-- --------------------------
-- Date Dimension
-- --------------------------
CREATE TABLE dim_date (
    date_key INTEGER PRIMARY KEY,
    -- surrogate key in YYYYMMDD format
    calendar_date DATE NOT NULL,
    year INT NOT NULL,
    month INT NOT NULL,
    month_name VARCHAR(20),
    quarter INT NOT NULL,
    week_of_year INT,
    day_of_month INT,
    day_of_week INT,
    day_name VARCHAR(20)
);
COMMENT ON TABLE dim_date IS 'Date dimension for time-based analysis. One row per calendar date.';
-- --------------------------
-- Patient Dimension
-- --------------------------
CREATE TABLE dim_patient (
    patient_key SERIAL PRIMARY KEY,
    patient_id INT UNIQUE NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    gender VARCHAR(20),
    age INT,
    age_group VARCHAR(50)
);
COMMENT ON TABLE dim_patient IS 'Patient dimension with demographic attributes. Surrogate key decouples from source system.';
-- --------------------------
-- Specialty Dimension
-- --------------------------
CREATE TABLE dim_specialty (
    specialty_key SERIAL PRIMARY KEY,
    specialty_id INT UNIQUE NOT NULL,
    specialty_name VARCHAR(255)
);
COMMENT ON TABLE dim_specialty IS 'Provider specialty dimension.';
-- --------------------------
-- Department Dimension
-- --------------------------
CREATE TABLE dim_department (
    department_key SERIAL PRIMARY KEY,
    department_id INT UNIQUE NOT NULL,
    department_name VARCHAR(255)
);
COMMENT ON TABLE dim_department IS 'Department dimension (e.g., Radiology, Surgery).';
-- --------------------------
-- Encounter Type Dimension
-- --------------------------
CREATE TABLE dim_encounter_type (
    encounter_type_key SERIAL PRIMARY KEY,
    encounter_type_name VARCHAR(50) UNIQUE NOT NULL
);
COMMENT ON TABLE dim_encounter_type IS 'Encounter type dimension (Outpatient, Inpatient, ER, etc.).';
-- --------------------------
-- Provider Dimension
-- --------------------------
CREATE TABLE dim_provider (
    provider_key SERIAL PRIMARY KEY,
    provider_id INT UNIQUE NOT NULL,
    provider_name VARCHAR(255),
    specialty_key INT REFERENCES dim_specialty(specialty_key),
    department_key INT REFERENCES dim_department(department_key)
);
COMMENT ON TABLE dim_provider IS 'Provider dimension with specialty + department FKs.';
-- --------------------------
-- Diagnosis Dimension
-- --------------------------
CREATE TABLE dim_diagnosis (
    diagnosis_key SERIAL PRIMARY KEY,
    diagnosis_id INT UNIQUE NOT NULL,
    icd10_code VARCHAR(20),
    description VARCHAR(500)
);
COMMENT ON TABLE dim_diagnosis IS 'Diagnosis dimension (ICD-10).';
-- --------------------------
-- Procedure Dimension
-- --------------------------
CREATE TABLE dim_procedure (
    procedure_key SERIAL PRIMARY KEY,
    procedure_id INT UNIQUE NOT NULL,
    cpt_code VARCHAR(20),
    description VARCHAR(500)
);
COMMENT ON TABLE dim_procedure IS 'Procedure dimension (CPT).';
-- ============================================================
-- FACT TABLE
-- ============================================================
-- --------------------------
-- Fact Encounters
-- --------------------------
CREATE TABLE fact_encounters (
    encounter_key BIGSERIAL PRIMARY KEY,
    -- Foreign keys
    date_key INT REFERENCES dim_date(date_key),
    patient_key INT REFERENCES dim_patient(patient_key),
    provider_key INT REFERENCES dim_provider(provider_key),
    specialty_key INT REFERENCES dim_specialty(specialty_key),
    department_key INT REFERENCES dim_department(department_key),
    encounter_type_key INT REFERENCES dim_encounter_type(encounter_type_key),
    -- Source system identifiers (optional but useful)
    encounter_id INT NOT NULL UNIQUE,
    -- Pre-aggregated metrics
    diagnosis_count INT DEFAULT 0,
    procedure_count INT DEFAULT 0,
    total_allowed_amount NUMERIC(12, 2) DEFAULT 0.00
);
COMMENT ON TABLE fact_encounters IS 'Core fact table: one row per encounter with pre-aggregated metrics.';
-- Recommended indexes
CREATE INDEX idx_fact_encounters_date ON fact_encounters(date_key);
CREATE INDEX idx_fact_encounters_provider ON fact_encounters(provider_key);
CREATE INDEX idx_fact_encounters_specialty ON fact_encounters(specialty_key);
CREATE INDEX idx_fact_encounters_enc_type ON fact_encounters(encounter_type_key);
-- ============================================================
-- BRIDGE TABLES (MANY-TO-MANY)
-- ============================================================
-- --------------------------
-- Bridge: Encounter ↔ Diagnoses
-- --------------------------
CREATE TABLE bridge_encounter_diagnosis (
    encounter_key BIGINT REFERENCES fact_encounters(encounter_key),
    diagnosis_key INT REFERENCES dim_diagnosis(diagnosis_key),
    PRIMARY KEY (encounter_key, diagnosis_key)
);
COMMENT ON TABLE bridge_encounter_diagnosis IS 'Bridge table for encounter-to-diagnosis relationship (many-to-many).';
CREATE INDEX idx_bridge_enc_diag_enc ON bridge_encounter_diagnosis(encounter_key);
CREATE INDEX idx_bridge_enc_diag_diag ON bridge_encounter_diagnosis(diagnosis_key);
-- --------------------------
-- Bridge: Encounter ↔ Procedures
-- --------------------------
CREATE TABLE bridge_encounter_procedure (
    encounter_key BIGINT REFERENCES fact_encounters(encounter_key),
    procedure_key INT REFERENCES dim_procedure(procedure_key),
    PRIMARY KEY (encounter_key, procedure_key)
);
COMMENT ON TABLE bridge_encounter_procedure IS 'Bridge table for encounter-to-procedure relationship (many-to-many).';
CREATE INDEX idx_bridge_enc_proc_enc ON bridge_encounter_procedure(encounter_key);
CREATE INDEX idx_bridge_enc_proc_proc ON bridge_encounter_procedure(procedure_key);