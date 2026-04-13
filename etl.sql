-- Loading dim_patient
INSERT INTO dim_patient (
        patient_id,
        full_name,
        gender,
        date_of_birth,
        age,
        age_group,
        effective_date
    )
SELECT p.patient_id,
    p.first_name || ' ' || p.last_name,
    p.gender,
    p.date_of_birth,
    DATE_PART('year', AGE(CURRENT_DATE, p.date_of_birth)),
    CASE
        WHEN DATE_PART('year', AGE(CURRENT_DATE, p.date_of_birth)) < 18 THEN 'Child'
        WHEN DATE_PART('year', AGE(CURRENT_DATE, p.date_of_birth)) < 65 THEN 'Adult'
        ELSE 'Senior'
    END,
    CURRENT_DATE
FROM patients p;
---- Adding data to dim_provider
INSERT INTO dim_provider (
        provider_id,
        provider_name,
        credential,
        specialty_name,
        specialty_code,
        department_name,
        department_floor,
        effective_date
    )
SELECT p.provider_id,
    p.first_name || ' ' || p.last_name,
    p.credential,
    s.specialty_name,
    s.specialty_code,
    d.department_name,
    d.floor,
    CURRENT_DATE
FROM providers p
    JOIN specialties s ON p.specialty_id = s.specialty_id
    JOIN departments d ON p.department_id = d.department_id;
--- Fact encounter table
INSERT INTO fact_encounter (
        patient_key,
        provider_key,
        encounter_date_key,
        discharge_date_key,
        primary_diagnosis_key,
        encounter_id,
        encounter_type,
        claim_amount,
        allowed_amount,
        length_of_stay
    )
SELECT dp.patient_key,
    dpr.provider_key,
    TO_CHAR(e.encounter_date, 'YYYYMMDD')::INT,
    TO_CHAR(e.discharge_date, 'YYYYMMDD')::INT,
    dd.diagnosis_key,
    e.encounter_id,
    e.encounter_type,
    b.claim_amount,
    b.allowed_amount,
    COALESCE(
        DATE_PART('day', e.discharge_date - e.encounter_date),
        0
    )
FROM encounters e
    JOIN dim_patient dp ON dp.patient_id = e.patient_id
    JOIN dim_provider dpr ON dpr.provider_id = e.provider_id
    LEFT JOIN billing b ON b.encounter_id = e.encounter_id
    LEFT JOIN encounter_diagnoses ed ON ed.encounter_id = e.encounter_id
    AND ed.diagnosis_sequence = 1
    LEFT JOIN dim_diagnosis dd ON dd.diagnosis_id = ed.diagnosis_id;
---Loading Dim Diagnosis
INSERT INTO dim_diagnosis (diagnosis_id, icd10_code, icd10_description)
SELECT diagnosis_id,
    icd10_code,
    icd10_description
FROM diagnoses;
--- Loading DIm Procedure
INSERT INTO dim_procedure (procedure_id, cpt_code, cpt_description)
SELECT procedure_id,
    cpt_code,
    cpt_description
FROM procedures;
--- Loading Date dimension
INSERT INTO dim_date (
        date_key,
        full_date,
        day,
        month,
        month_name,
        quarter,
        year,
        day_of_week,
        is_weekend
    )
SELECT TO_CHAR(d, 'YYYYMMDD')::INT,
    d,
    EXTRACT(
        DAY
        FROM d
    ),
    EXTRACT(
        MONTH
        FROM d
    ),
    TO_CHAR(d, 'Month'),
    EXTRACT(
        QUARTER
        FROM d
    ),
    EXTRACT(
        YEAR
        FROM d
    ),
    TO_CHAR(d, 'Day'),
    CASE
        WHEN EXTRACT(
            DOW
            FROM d
        ) IN (0, 6) THEN TRUE
        ELSE FALSE
    END
FROM generate_series('2024-01-01'::date, '2025-12-31', '1 day') d;
--- Supporting Encounter Diagnosis Fact table
INSERT INTO fact_encounter_diagnosis (
        encounter_key,
        diagnosis_key,
        diagnosis_sequence
    )
SELECT fe.encounter_key,
    dd.diagnosis_key,
    ed.diagnosis_sequence
FROM encounter_diagnoses ed
    JOIN fact_encounter fe ON fe.encounter_id = ed.encounter_id
    JOIN dim_diagnosis dd ON dd.diagnosis_id = ed.diagnosis_id;
---- Supporting Encounter Procedure fact table
INSERT INTO fact_encounter_procedure (
        encounter_key,
        procedure_key,
        procedure_date_key
    )
SELECT fe.encounter_key,
    dp.procedure_key,
    dd.date_key
FROM encounter_procedures ep
    JOIN fact_encounter fe ON fe.encounter_id = ep.encounter_id
    JOIN dim_procedure dp ON dp.procedure_id = ep.procedure_id
    JOIN dim_date dd ON dd.full_date = ep.procedure_date;
select *
from fact_encounter_procedure;