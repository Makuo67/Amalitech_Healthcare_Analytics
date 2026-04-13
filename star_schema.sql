----------------------
--- Patient Dimension
----------------------
CREATE TABLE dim_patient (
    patient_key SERIAL PRIMARY KEY,
    patient_id INT UNIQUE,
    full_name VARCHAR(200),
    gender CHAR(1),
    date_of_birth DATE,
    age INT,
    age_group VARCHAR(50),
    effective_date DATE,
    expiry_date DATE
);
---------------------
-- Provider Dimension
----------------------
CREATE TABLE dim_provider (
    provider_key SERIAL PRIMARY KEY,
    provider_id INT UNIQUE,
    provider_name VARCHAR(200),
    credential VARCHAR(20),
    specialty_name VARCHAR(100),
    specialty_code VARCHAR(10),
    department_name VARCHAR(100),
    department_floor INT,
    effective_date DATE,
    expiry_date DATE
);
--------------
-- Date Dimention
------------------
CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    -- YYYYMMDD
    full_date DATE NOT NULL UNIQUE,
    day INT,
    month INT,
    month_name VARCHAR(20),
    quarter INT,
    year INT,
    day_of_week VARCHAR(20),
    is_weekend BOOLEAN
);
-------------------------
--- Diagnosis Dimension
-------------------------
CREATE TABLE dim_diagnosis (
    diagnosis_key SERIAL PRIMARY KEY,
    diagnosis_id INT,
    icd10_code VARCHAR(10),
    icd10_description VARCHAR(200)
);
-------------------------
--- Procedure Dimension
-------------------------
CREATE TABLE dim_procedure (
    procedure_key SERIAL PRIMARY KEY,
    procedure_id INT,
    cpt_code VARCHAR(10),
    cpt_description VARCHAR(200)
);
----------------------------
---- Encounter Fact Table
----------------------------
CREATE TABLE fact_encounter (
    encounter_key SERIAL PRIMARY KEY,
    -- Foreign Keys
    patient_key INT NOT NULL,
    provider_key INT NOT NULL,
    encounter_date_key INT NOT NULL,
    discharge_date_key INT,
    primary_diagnosis_key INT,
    -- Degenerate dimension
    encounter_id INT,
    encounter_type VARCHAR(50),
    -- Measures
    claim_amount DECIMAL(12, 2),
    allowed_amount DECIMAL(12, 2),
    length_of_stay INT CHECK (length_of_stay >= 0),
    CONSTRAINT fk_fact_encounter_patient FOREIGN KEY (patient_key) REFERENCES dim_patient(patient_key),
    CONSTRAINT fk_fact_encounter_provider FOREIGN KEY (provider_key) REFERENCES dim_provider(provider_key),
    CONSTRAINT fk_fact_encounter_date FOREIGN KEY (encounter_date_key) REFERENCES dim_date(date_key),
    CONSTRAINT fk_fact_encounter_discharge_date FOREIGN KEY (discharge_date_key) REFERENCES dim_date(date_key),
    CONSTRAINT fk_fact_encounter_diagnosis FOREIGN KEY (primary_diagnosis_key) REFERENCES dim_diagnosis(diagnosis_key)
);
---- Indexes for the fact table
CREATE INDEX idx_fact_encounter_patient ON fact_encounter(patient_key);
CREATE INDEX idx_fact_encounter_provider ON fact_encounter(provider_key);
CREATE INDEX idx_fact_encounter_date ON fact_encounter(encounter_date_key);
---------------------------------
-- Supporting Fact for Encounter Diagnosis
---------------------------------
CREATE TABLE fact_encounter_diagnosis (
    encounter_diagnosis_key SERIAL PRIMARY KEY,
    encounter_key INT,
    diagnosis_key INT,
    diagnosis_sequence INT,
    CONSTRAINT fk_fact_encounter_diagnosis_encounter_key FOREIGN KEY (encounter_key) REFERENCES fact_encounter(encounter_key),
    CONSTRAINT fk_fact_encounter_diagnosis_diagnosis_key FOREIGN KEY (diagnosis_key) REFERENCES dim_diagnosis(diagnosis_key)
);
---- Index for fact diagnosis
CREATE INDEX idx_fact_enc_diag_encounter ON fact_encounter_diagnosis(encounter_key);
-----------------------------------
-- Supporting Fact for Procedures
------------------------------------
CREATE TABLE fact_encounter_procedure (
    encounter_procedure_key SERIAL PRIMARY KEY,
    encounter_key INT,
    procedure_key INT,
    procedure_date_key INT,
    CONSTRAINT fk_fact_encounter_procedure_encounter_key FOREIGN KEY (encounter_key) REFERENCES fact_encounter(encounter_key),
    CONSTRAINT fk_fact_encounter_procedure_procedure_key FOREIGN KEY (procedure_key) REFERENCES dim_procedure(procedure_key),
    CONSTRAINT fk_fact_encounter_procedure_procedure_date_key FOREIGN KEY (procedure_date_key) REFERENCES dim_date(date_key)
);
---- Index for fact procedures
CREATE INDEX idx_fact_enc_proc_encounter ON fact_encounter_procedure(encounter_key);