-- ==============================================================================
-- Portfolio Project: Hospital Readmission Analytics
-- Author: Data Analyst Intern Candidate
-- File: 04_analysis.sql
-- Purpose: In-depth SQL Analysis of 30-Day Hospital Readmission Associations
-- Target Database: hospital_analytics (MySQL 8.0+)
-- ==============================================================================

USE hospital_analytics;

-- ------------------------------------------------------------------------------
-- 1. Overall Baseline Metrics (All Eligible Encounters)
-- Measures baseline 30-day readmission rate across the 99,340 clean encounters.
-- ------------------------------------------------------------------------------
SELECT 
    COUNT(*) AS total_encounters,
    SUM(readmit_30) AS readmissions_30_days,
    ROUND(AVG(readmit_30) * 100, 2) AS readmission_rate_pct,
    ROUND(AVG(time_in_hospital), 2) AS avg_length_of_stay,
    ROUND(AVG(num_medications), 2) AS avg_num_medications
FROM clean_encounters;


-- ------------------------------------------------------------------------------
-- 2. 30-Day Readmission Rate by Age Group
-- Evaluates readmission risk progression across chronological age brackets.
-- ------------------------------------------------------------------------------
SELECT 
    age,
    COUNT(*) AS total_encounters,
    SUM(readmit_30) AS readmissions_30,
    ROUND(AVG(readmit_30) * 100, 2) AS readmission_rate_pct,
    ROUND(AVG(time_in_hospital), 2) AS avg_length_of_stay
FROM clean_encounters
GROUP BY age
ORDER BY age;


-- ------------------------------------------------------------------------------
-- 3. 30-Day Readmission Rate by Prior Inpatient Visits Group
-- Evaluates the association between historical utilization and readmission risk.
-- ------------------------------------------------------------------------------
SELECT 
    prior_visits_group,
    COUNT(*) AS total_encounters,
    SUM(readmit_30) AS readmissions_30,
    ROUND(AVG(readmit_30) * 100, 2) AS readmission_rate_pct,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM clean_encounters), 2) AS share_of_encounters_pct
FROM clean_encounters
GROUP BY prior_visits_group
ORDER BY 
    CASE prior_visits_group
        WHEN '0' THEN 1
        WHEN '1-2' THEN 2
        WHEN '3+' THEN 3
    END;


-- ------------------------------------------------------------------------------
-- 4. 30-Day Readmission Rate by Length of Stay (1 to 14 Days)
-- Evaluates whether longer hospital stays associate with elevated readmission risk.
-- ------------------------------------------------------------------------------
SELECT 
    time_in_hospital AS los_days,
    COUNT(*) AS total_encounters,
    SUM(readmit_30) AS readmissions_30,
    ROUND(AVG(readmit_30) * 100, 2) AS readmission_rate_pct
FROM clean_encounters
GROUP BY time_in_hospital
ORDER BY time_in_hospital ASC;


-- ------------------------------------------------------------------------------
-- 5. Specialties Ranked by Readmission Rate (Encounters >= 500)
-- Utilizes CTE and RANK() window function to identify high-risk clinical specialties.
-- ------------------------------------------------------------------------------
WITH specialty_metrics AS (
    SELECT 
        medical_specialty,
        COUNT(*) AS total_encounters,
        SUM(readmit_30) AS readmissions_30,
        ROUND(AVG(readmit_30) * 100, 2) AS readmission_rate_pct,
        ROUND(AVG(time_in_hospital), 2) AS avg_los,
        ROUND(AVG(num_medications), 2) AS avg_meds
    FROM clean_encounters
    GROUP BY medical_specialty
    HAVING COUNT(*) >= 500
)
SELECT 
    RANK() OVER (ORDER BY readmission_rate_pct DESC) AS specialty_rank,
    medical_specialty,
    total_encounters,
    readmissions_30,
    readmission_rate_pct,
    avg_los,
    avg_meds
FROM specialty_metrics
ORDER BY specialty_rank ASC;


-- ------------------------------------------------------------------------------
-- 6. 30-Day Readmission Rate by Glycemic Control (A1Cresult)
-- Analyzes testing patterns and association between HbA1c testing and outcomes.
-- ------------------------------------------------------------------------------
SELECT 
    A1Cresult,
    COUNT(*) AS total_encounters,
    SUM(readmit_30) AS readmissions_30,
    ROUND(AVG(readmit_30) * 100, 2) AS readmission_rate_pct,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM clean_encounters), 2) AS cohort_share_pct
FROM clean_encounters
GROUP BY A1Cresult
ORDER BY readmission_rate_pct DESC;


-- ------------------------------------------------------------------------------
-- 7. 30-Day Readmission Rate by Medication Count Buckets (Polypharmacy Analysis)
-- Evaluates whether high pharmaceutical complexity correlates with readmission.
-- ------------------------------------------------------------------------------
WITH med_buckets AS (
    SELECT 
        encounter_id,
        num_medications,
        readmit_30,
        CASE 
            WHEN num_medications BETWEEN 1 AND 10 THEN '1-10 (Low)'
            WHEN num_medications BETWEEN 11 AND 20 THEN '11-20 (Moderate)'
            WHEN num_medications BETWEEN 21 AND 30 THEN '21-30 (High)'
            ELSE '31+ (Polypharmacy)'
        END AS med_bucket,
        CASE 
            WHEN num_medications BETWEEN 1 AND 10 THEN 1
            WHEN num_medications BETWEEN 11 AND 20 THEN 2
            WHEN num_medications BETWEEN 21 AND 30 THEN 3
            ELSE 4
        END AS sort_order
    FROM clean_encounters
)
SELECT 
    med_bucket,
    COUNT(*) AS total_encounters,
    SUM(readmit_30) AS readmissions_30,
    ROUND(AVG(readmit_30) * 100, 2) AS readmission_rate_pct,
    MIN(num_medications) AS min_meds,
    MAX(num_medications) AS max_meds
FROM med_buckets
GROUP BY med_bucket, sort_order
ORDER BY sort_order ASC;


-- ------------------------------------------------------------------------------
-- 8a. 30-Day Readmission Rate by Gender
-- Demographic baseline breakdown across biological sexes.
-- ------------------------------------------------------------------------------
SELECT 
    gender,
    COUNT(*) AS total_encounters,
    SUM(readmit_30) AS readmissions_30,
    ROUND(AVG(readmit_30) * 100, 2) AS readmission_rate_pct
FROM clean_encounters
GROUP BY gender
ORDER BY readmission_rate_pct DESC;


-- ------------------------------------------------------------------------------
-- 8b. 30-Day Readmission Rate by Race
-- Demographic breakdown including handling of missing (NULL) values.
-- ------------------------------------------------------------------------------
SELECT 
    COALESCE(race, 'Missing / Unspecified') AS race,
    COUNT(*) AS total_encounters,
    SUM(readmit_30) AS readmissions_30,
    ROUND(AVG(readmit_30) * 100, 2) AS readmission_rate_pct,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM clean_encounters), 2) AS share_of_encounters_pct
FROM clean_encounters
GROUP BY race
ORDER BY total_encounters DESC;


-- ------------------------------------------------------------------------------
-- 9. Robustness Checks on `first_encounters` (Single-Encounter Patient Cohort)
-- Verifying whether repeat-patient overrepresentation distorts conclusions.
-- ------------------------------------------------------------------------------

-- 9a. Overall Robustness Baseline
SELECT 
    'first_encounters' AS cohort,
    COUNT(*) AS total_encounters,
    SUM(readmit_30) AS readmissions_30,
    ROUND(AVG(readmit_30) * 100, 2) AS readmission_rate_pct,
    ROUND(AVG(time_in_hospital), 2) AS avg_length_of_stay,
    ROUND(AVG(num_medications), 2) AS avg_num_medications
FROM first_encounters;

-- 9b. Readmission Rate by Age Group (First Encounters)
SELECT 
    age,
    COUNT(*) AS total_encounters,
    SUM(readmit_30) AS readmissions_30,
    ROUND(AVG(readmit_30) * 100, 2) AS readmission_rate_pct
FROM first_encounters
GROUP BY age
ORDER BY age;

-- 9c. Readmission Rate by Prior Inpatient Visits Group (First Encounters)
SELECT 
    prior_visits_group,
    COUNT(*) AS total_encounters,
    SUM(readmit_30) AS readmissions_30,
    ROUND(AVG(readmit_30) * 100, 2) AS readmission_rate_pct,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM first_encounters), 2) AS share_of_encounters_pct
FROM first_encounters
GROUP BY prior_visits_group
ORDER BY 
    CASE prior_visits_group
        WHEN '0' THEN 1
        WHEN '1-2' THEN 2
        WHEN '3+' THEN 3
    END;
