-- ==============================================================================
-- Portfolio Project: Hospital Readmission Analytics
-- Author: Data Analyst Intern Candidate
-- File: 02_cleaning.sql
-- Purpose: Data Cleaning, Transformation, and Cohort Creation
-- Target Database: hospital_analytics (MySQL 8.0+)
-- ==============================================================================

USE hospital_analytics;

-- ------------------------------------------------------------------------------
-- 1. Pre-Cleaning Filter Impact Assessment (Audit Log)
-- Quantify the number of records affected by each exclusion and transformation rule.
-- ------------------------------------------------------------------------------

-- Rule A: Count encounters with invalid/unknown gender
SELECT 
    COUNT(*) AS gender_invalid_count
FROM raw_encounters
WHERE gender = 'Unknown/Invalid';

-- Rule B: Count encounters where patient expired or entered hospice
-- Rationale: Readmission requires survival post-discharge. Patients who died 
-- in-hospital or entered hospice care cannot be readmitted. Retaining them 
-- artificially deflates the true 30-day readmission risk denominator.
SELECT 
    discharge_disposition_id,
    COUNT(*) AS encounter_count
FROM raw_encounters
WHERE discharge_disposition_id IN (11, 13, 14, 19, 20, 21)
GROUP BY discharge_disposition_id;

-- Rule C: Check overlap between invalid gender and expired/hospice
SELECT 
    COUNT(*) AS overlap_count
FROM raw_encounters
WHERE gender = 'Unknown/Invalid'
  AND discharge_disposition_id IN (11, 13, 14, 19, 20, 21);

-- Rule D: Race '?' to NULL, medical_specialty '?' to 'Unknown', weight dropped
-- Rationale: 'weight' has 96.86% missing data. Imputation would introduce 
-- massive bias or noise. Dropping it is best practice in clinical analytics.
SELECT 
    SUM(CASE WHEN race = '?' THEN 1 ELSE 0 END) AS race_question_mark_count,
    SUM(CASE WHEN medical_specialty = '?' THEN 1 ELSE 0 END) AS medical_specialty_question_mark_count,
    SUM(CASE WHEN weight = '?' THEN 1 ELSE 0 END) AS weight_dropped_missing_count
FROM raw_encounters;


-- ------------------------------------------------------------------------------
-- 2. Build Clean Cohort: `clean_encounters`
-- Applying business logic, feature engineering, and selecting required columns.
-- ------------------------------------------------------------------------------

DROP TABLE IF EXISTS clean_encounters;

CREATE TABLE clean_encounters AS
SELECT 
    encounter_id,
    patient_nbr,
    -- Replace '?' with NULL for race
    CASE 
        WHEN race = '?' THEN NULL 
        ELSE race 
    END AS race,
    gender,
    age,
    time_in_hospital,
    -- Impute missing medical specialty as 'Unknown'
    CASE 
        WHEN medical_specialty = '?' THEN 'Unknown' 
        ELSE medical_specialty 
    END AS medical_specialty,
    num_lab_procedures,
    num_medications,
    number_outpatient,
    number_emergency,
    number_inpatient,
    -- Feature engineering: prior inpatient visits category
    CASE 
        WHEN number_inpatient = 0 THEN '0'
        WHEN number_inpatient BETWEEN 1 AND 2 THEN '1-2'
        ELSE '3+'
    END AS prior_visits_group,
    A1Cresult,
    insulin,
    diabetesMed,
    readmitted,
    -- Binary target: 1 if readmitted within 30 days, else 0
    CASE 
        WHEN readmitted = '<30' THEN 1 
        ELSE 0 
    END AS readmit_30
FROM raw_encounters
WHERE gender != 'Unknown/Invalid'
  AND discharge_disposition_id NOT IN (11, 13, 14, 19, 20, 21);

-- Add primary key constraint on encounter_id
ALTER TABLE clean_encounters ADD PRIMARY KEY (encounter_id);

-- Create secondary index for patient and lookup queries
CREATE INDEX idx_patient_nbr ON clean_encounters (patient_nbr);
CREATE INDEX idx_readmit_30 ON clean_encounters (readmit_30);


-- ------------------------------------------------------------------------------
-- 3. Robustness Cohort: `first_encounters`
-- Retaining only each patient's first chronological encounter using ROW_NUMBER()
-- Window function to prevent repeated measures bias (patients with frequent visits
-- over-indexing in the aggregate statistics).
-- ------------------------------------------------------------------------------

DROP TABLE IF EXISTS first_encounters;

CREATE TABLE first_encounters AS
WITH ranked_patient_encounters AS (
    SELECT 
        encounter_id,
        patient_nbr,
        race,
        gender,
        age,
        time_in_hospital,
        medical_specialty,
        num_lab_procedures,
        num_medications,
        number_outpatient,
        number_emergency,
        number_inpatient,
        prior_visits_group,
        A1Cresult,
        insulin,
        diabetesMed,
        readmitted,
        readmit_30,
        ROW_NUMBER() OVER (
            PARTITION BY patient_nbr 
            ORDER BY encounter_id ASC
        ) AS encounter_seq
    FROM clean_encounters
)
SELECT 
    encounter_id,
    patient_nbr,
    race,
    gender,
    age,
    time_in_hospital,
    medical_specialty,
    num_lab_procedures,
    num_medications,
    number_outpatient,
    number_emergency,
    number_inpatient,
    prior_visits_group,
    A1Cresult,
    insulin,
    diabetesMed,
    readmitted,
    readmit_30
FROM ranked_patient_encounters
WHERE encounter_seq = 1;

-- Add primary key constraint on encounter_id
ALTER TABLE first_encounters ADD PRIMARY KEY (encounter_id);
