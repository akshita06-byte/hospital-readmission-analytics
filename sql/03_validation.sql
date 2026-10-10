-- ==============================================================================
-- Portfolio Project: Hospital Readmission Analytics
-- Author: Data Analyst Intern Candidate
-- File: 03_validation.sql
-- Purpose: Post-Cleaning Data Quality Validation & Pipeline Integrity Checks
-- Target Database: hospital_analytics (MySQL 8.0+)
-- ==============================================================================

USE hospital_analytics;

-- ------------------------------------------------------------------------------
-- 1. Cohort Volume & Attrition Validation
-- Verify row counts across all pipeline stages: raw -> clean -> first encounters.
-- ------------------------------------------------------------------------------
SELECT 
    'raw_encounters' AS dataset_stage,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT patient_nbr) AS unique_patients,
    0 AS rows_removed,
    100.0 AS pct_retained
FROM raw_encounters
UNION ALL
SELECT 
    'clean_encounters' AS dataset_stage,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT patient_nbr) AS unique_patients,
    (SELECT COUNT(*) FROM raw_encounters) - COUNT(*) AS rows_removed,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM raw_encounters), 2) AS pct_retained
FROM clean_encounters
UNION ALL
SELECT 
    'first_encounters' AS dataset_stage,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT patient_nbr) AS unique_patients,
    (SELECT COUNT(*) FROM clean_encounters) - COUNT(*) AS rows_removed,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM clean_encounters), 2) AS pct_retained
FROM first_encounters;


-- ------------------------------------------------------------------------------
-- 2. Column Nullability Audit (clean_encounters)
-- Verify that race contains intentional NULLs, while all other analytical 
-- columns have zero NULLs.
-- ------------------------------------------------------------------------------
SELECT 
    COUNT(*) AS total_clean_rows,
    SUM(CASE WHEN encounter_id IS NULL THEN 1 ELSE 0 END) AS null_encounter_id,
    SUM(CASE WHEN patient_nbr IS NULL THEN 1 ELSE 0 END) AS null_patient_nbr,
    SUM(CASE WHEN race IS NULL THEN 1 ELSE 0 END) AS null_race,
    ROUND(100.0 * SUM(CASE WHEN race IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS null_race_pct,
    SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END) AS null_gender,
    SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END) AS null_age,
    SUM(CASE WHEN time_in_hospital IS NULL THEN 1 ELSE 0 END) AS null_time_in_hospital,
    SUM(CASE WHEN medical_specialty IS NULL THEN 1 ELSE 0 END) AS null_medical_specialty,
    SUM(CASE WHEN num_lab_procedures IS NULL THEN 1 ELSE 0 END) AS null_num_lab_procedures,
    SUM(CASE WHEN num_medications IS NULL THEN 1 ELSE 0 END) AS null_num_medications,
    SUM(CASE WHEN number_outpatient IS NULL THEN 1 ELSE 0 END) AS null_number_outpatient,
    SUM(CASE WHEN number_emergency IS NULL THEN 1 ELSE 0 END) AS null_number_emergency,
    SUM(CASE WHEN number_inpatient IS NULL THEN 1 ELSE 0 END) AS null_number_inpatient,
    SUM(CASE WHEN prior_visits_group IS NULL THEN 1 ELSE 0 END) AS null_prior_visits_group,
    SUM(CASE WHEN A1Cresult IS NULL THEN 1 ELSE 0 END) AS null_A1Cresult,
    SUM(CASE WHEN insulin IS NULL THEN 1 ELSE 0 END) AS null_insulin,
    SUM(CASE WHEN diabetesMed IS NULL THEN 1 ELSE 0 END) AS null_diabetesMed,
    SUM(CASE WHEN readmitted IS NULL THEN 1 ELSE 0 END) AS null_readmitted,
    SUM(CASE WHEN readmit_30 IS NULL THEN 1 ELSE 0 END) AS null_readmit_30
FROM clean_encounters;


-- ------------------------------------------------------------------------------
-- 3. Binary Target Integrity Check (readmit_30)
-- Confirm readmit_30 strictly contains {0, 1} and maps 1:1 with readmitted = '<30'.
-- ------------------------------------------------------------------------------
SELECT 
    readmitted,
    readmit_30,
    COUNT(*) AS encounter_count
FROM clean_encounters
GROUP BY readmitted, readmit_30
ORDER BY readmit_30 DESC, encounter_count DESC;

-- Verification: check for any illegal values outside 0 and 1
SELECT 
    COUNT(*) AS invalid_readmit_30_count
FROM clean_encounters
WHERE readmit_30 NOT IN (0, 1) OR readmit_30 IS NULL;


-- ------------------------------------------------------------------------------
-- 4. Categorical Feature Integrity (prior_visits_group)
-- Verify categorization logic mapping number_inpatient to ('0', '1-2', '3+').
-- ------------------------------------------------------------------------------
SELECT 
    prior_visits_group,
    MIN(number_inpatient) AS min_inpatient,
    MAX(number_inpatient) AS max_inpatient,
    COUNT(*) AS encounter_count
FROM clean_encounters
GROUP BY prior_visits_group
ORDER BY min_inpatient ASC;


-- ------------------------------------------------------------------------------
-- 5. Primary Key & Deduplication Integrity Check
-- Confirm clean_encounters has zero duplicate encounter_ids,
-- and first_encounters has strictly one record per patient_nbr.
-- ------------------------------------------------------------------------------
SELECT 
    'clean_encounters duplicate encounter_ids' AS test_name,
    COUNT(*) AS violation_count
FROM (
    SELECT encounter_id 
    FROM clean_encounters 
    GROUP BY encounter_id 
    HAVING COUNT(*) > 1
) sub
UNION ALL
SELECT 
    'first_encounters duplicate patient_nbrs' AS test_name,
    COUNT(*) AS violation_count
FROM (
    SELECT patient_nbr 
    FROM first_encounters 
    GROUP BY patient_nbr 
    HAVING COUNT(*) > 1
) sub;
