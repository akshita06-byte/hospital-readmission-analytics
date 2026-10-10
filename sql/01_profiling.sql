-- ==============================================================================
-- Portfolio Project: Hospital Readmission Analytics
-- Author: Data Analyst Intern Candidate
-- File: 01_profiling.sql
-- Purpose: Initial Data Profiling of raw_encounters table
-- Target Database: hospital_analytics (MySQL 8.0+)
-- ==============================================================================

USE hospital_analytics;

-- ------------------------------------------------------------------------------
-- 1. Total Rows & Unique Patient Population
-- Assess total encounter volume versus unique patients to detect repeat admissions.
-- ------------------------------------------------------------------------------
SELECT 
    COUNT(*) AS total_encounters,
    COUNT(DISTINCT patient_nbr) AS unique_patients,
    ROUND(COUNT(*) / COUNT(DISTINCT patient_nbr), 2) AS avg_encounters_per_patient
FROM raw_encounters;


-- ------------------------------------------------------------------------------
-- 2. Primary Key Integrity Check
-- Check for duplicate encounter_id records to ensure entity integrity.
-- ------------------------------------------------------------------------------
SELECT 
    encounter_id, 
    COUNT(*) AS occurrences
FROM raw_encounters
GROUP BY encounter_id
HAVING COUNT(*) > 1;


-- ------------------------------------------------------------------------------
-- 3. Missing Value Analysis ('?' placeholders)
-- In the UCI dataset, missing values are denoted by the character '?'.
-- We assess the frequency and percentage of missingness across key clinical columns.
-- ------------------------------------------------------------------------------
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN race = '?' THEN 1 ELSE 0 END) AS race_missing_count,
    ROUND(100.0 * SUM(CASE WHEN race = '?' THEN 1 ELSE 0 END) / COUNT(*), 2) AS race_missing_pct,
    
    SUM(CASE WHEN weight = '?' THEN 1 ELSE 0 END) AS weight_missing_count,
    ROUND(100.0 * SUM(CASE WHEN weight = '?' THEN 1 ELSE 0 END) / COUNT(*), 2) AS weight_missing_pct,
    
    SUM(CASE WHEN payer_code = '?' THEN 1 ELSE 0 END) AS payer_code_missing_count,
    ROUND(100.0 * SUM(CASE WHEN payer_code = '?' THEN 1 ELSE 0 END) / COUNT(*), 2) AS payer_code_missing_pct,
    
    SUM(CASE WHEN medical_specialty = '?' THEN 1 ELSE 0 END) AS medical_specialty_missing_count,
    ROUND(100.0 * SUM(CASE WHEN medical_specialty = '?' THEN 1 ELSE 0 END) / COUNT(*), 2) AS medical_specialty_missing_pct,
    
    SUM(CASE WHEN diag_1 = '?' THEN 1 ELSE 0 END) AS diag_1_missing_count,
    ROUND(100.0 * SUM(CASE WHEN diag_1 = '?' THEN 1 ELSE 0 END) / COUNT(*), 2) AS diag_1_missing_pct,
    
    SUM(CASE WHEN diag_2 = '?' THEN 1 ELSE 0 END) AS diag_2_missing_count,
    ROUND(100.0 * SUM(CASE WHEN diag_2 = '?' THEN 1 ELSE 0 END) / COUNT(*), 2) AS diag_2_missing_pct,
    
    SUM(CASE WHEN diag_3 = '?' THEN 1 ELSE 0 END) AS diag_3_missing_count,
    ROUND(100.0 * SUM(CASE WHEN diag_3 = '?' THEN 1 ELSE 0 END) / COUNT(*), 2) AS diag_3_missing_pct
FROM raw_encounters;


-- ------------------------------------------------------------------------------
-- 4. Readmission Outcome Distribution
-- Profiling target variable `readmitted` (<30, >30, NO).
-- ------------------------------------------------------------------------------
SELECT 
    readmitted,
    COUNT(*) AS encounter_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM raw_encounters), 2) AS percentage
FROM raw_encounters
GROUP BY readmitted
ORDER BY encounter_count DESC;


-- ------------------------------------------------------------------------------
-- 5. Age Distribution
-- Check representation across 10-year age buckets.
-- ------------------------------------------------------------------------------
SELECT 
    age,
    COUNT(*) AS encounter_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM raw_encounters), 2) AS percentage
FROM raw_encounters
GROUP BY age
ORDER BY age;


-- ------------------------------------------------------------------------------
-- 6. Gender Distribution
-- Check for invalid/unknown values needing cleaning.
-- ------------------------------------------------------------------------------
SELECT 
    gender,
    COUNT(*) AS encounter_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM raw_encounters), 2) AS percentage
FROM raw_encounters
GROUP BY gender
ORDER BY encounter_count DESC;


-- ------------------------------------------------------------------------------
-- 7. Discharge Disposition Distribution
-- Joining raw encounters to lookup table to profile discharge statuses,
-- specifically identifying expired or hospice discharges (11, 13, 14, 19, 20, 21).
-- ------------------------------------------------------------------------------
SELECT 
    r.discharge_disposition_id,
    COALESCE(d.description, 'Unknown Description') AS disposition_description,
    COUNT(*) AS encounter_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM raw_encounters), 2) AS percentage,
    CASE 
        WHEN r.discharge_disposition_id IN (11, 13, 14, 19, 20, 21) THEN 'Exclude (Expired / Hospice)'
        ELSE 'Retain'
    END AS eligibility_status
FROM raw_encounters r
LEFT JOIN discharge_disposition_lookup d 
    ON r.discharge_disposition_id = d.discharge_disposition_id
GROUP BY r.discharge_disposition_id, d.description
ORDER BY encounter_count DESC;
