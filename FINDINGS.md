# Hospital Readmission Analytics: Clinical Findings & Methodology Report

**Author:** Data Analyst Intern Candidate  
**Project:** 30-Day Hospital Readmission Analytics (Diabetes 130-US Hospitals Cohort)  
**Target Organization:** Innovaccer (Healthcare Data Analytics)  
**Database:** MySQL 8.0 (`hospital_analytics`) | **Dataset:** UCI ML Repository (1999–2008)  

> **Methodological Note on Study Design:** All findings, comparisons, and metrics reported in this document represent observational statistical associations derived from historical administrative encounter data. They do not establish, claim, or imply causal relationships.

---

## Executive Summary

Hospital readmissions within 30 days are a primary quality benchmark under the Centers for Medicare & Medicaid Services (CMS) Hospital Readmissions Reduction Program (HRRP). This project investigates clinical, demographic, and operational factors associated with 30-day readmissions across 101,766 raw inpatient encounters from 130 US hospitals.

Following data hygiene and clinical cohort filtering, **99,340 clean encounters** were analyzed. The overall **30-day readmission rate was 11.39%** (11,314 encounters). A robustness cohort of **69,987 unique first encounters** yielded an **8.98% readmission rate**, confirming that repeat patient hospitalizations influence aggregate encounter-level rates while core associational patterns remain consistent.

---

## Key Analytical Findings

Every figure reported below is derived directly from executed SQL queries on the cleaned dataset.

### Finding 1: Prior Inpatient Hospitalizations Show the Strongest Association with 30-Day Readmissions
* **Supporting Data:**
  * **0 prior inpatient visits:** Readmission rate of **8.59%** (5,690 readmissions / 66,242 encounters; 66.68% of cohort).
  * **1–2 prior inpatient visits:** Readmission rate of **14.55%** (3,825 readmissions / 26,284 encounters; 26.46% of cohort).
  * **3+ prior inpatient visits:** Readmission rate of **26.40%** (1,799 readmissions / 6,814 encounters; 6.86% of cohort).
  * Patients with 3+ prior visits had a readmission rate **over 3.07 times higher** than patients with zero prior visits.
  * In the single-encounter robustness cohort (`first_encounters`), the readmission rate for patients with 3+ prior visits remained higher at **26.45%** vs **8.13%** for 0 prior visits (a **3.25x ratio**).
* **What it might mean:** High historical hospital utilization is often associated with advanced chronic multi-morbidity and potential gaps in outpatient disease management, suggesting that post-discharge transition workflows may provide the highest relative utility when focused on patients with prior inpatient stays.
* **Limitation:** Administrative encounter data lacks granular clinical staging (e.g., eGFR, left ventricular ejection fraction, or Charlson Comorbidity Index), meaning prior utilization serves as an observational proxy rather than a calibrated clinical severity score.

---

### Finding 2: Nephrology Inpatient Encounters Exhibited the Highest Readmission Rate Among High-Volume Specialties
* **Supporting Data:**
  * Among clinical specialties with >= 500 encounters, **Nephrology ranked #1** with a **16.11% readmission rate** (248 readmissions / 1,539 encounters; average length of stay 5.04 days; average 17.64 medications).
  * **Vascular Surgery ranked #2** with **14.10%** (74 / 525 encounters; average 20.90 medications).
  * **Psychiatry ranked #3** with **12.19%** (104 / 853 encounters; average length of stay 6.40 days).
  * In contrast, high-volume specialties such as **Cardiology** had an **8.03%** readmission rate (424 / 5,278 encounters) and **Cardiovascular/Thoracic Surgery** had **6.70%** (43 / 642 encounters).
* **What it might mean:** Diabetic patients admitted under Nephrology frequently present complex comorbidities such as chronic kidney disease (CKD) or end-stage renal disease (ESRD), where fluid retention, electrolyte fluctuations, and vascular access issues are common clinical challenges associated with subsequent acute care visits.
* **Limitation:** 48.94% of clean encounters had missing specialty information (recorded as `'Unknown'`, with an 11.83% readmission rate). Incomplete specialty documentation across participating hospitals could influence specialty-level rankings.

---

### Finding 3: Higher Medication Counts and Longer Stays Associated with Higher Readmission Rates
* **Supporting Data:**
  * **Medication Count Tiers:**
    * Low (1–10 medications): **9.21%** readmission rate (2,332 / 25,311 encounters).
    * Moderate (11–20 medications): **11.66%** readmission rate (5,938 / 50,942 encounters).
    * High (21–30 medications): **13.24%** readmission rate (2,394 / 18,076 encounters).
    * Very High (31+ medications): **12.97%** readmission rate (650 / 5,011 encounters).
  * **Length of Stay (LOS):**
    * 1-day stays had a readmission rate of **8.39%** (1,160 / 13,822 encounters).
    * 4-day stays had a readmission rate of **11.99%** (1,641 / 13,684 encounters).
    * Stays between 8 and 10 days had readmission rates of **14.28% to 14.81%**.
* **What it might mean:** Higher pharmaceutical counts and extended lengths of stay are typical markers of acute clinical complexity and multimorbidity, which are historically associated with higher rates of post-discharge re-hospitalization.
* **Limitation:** The dataset records the count of distinct generic medication names administered during hospitalization rather than discharge prescription details, adherence tracking, or post-discharge adverse drug events.

---

### Finding 4: Inpatient Glycemic Testing Documentation: 83% of Encounters Had No Inpatient HbA1c Recorded
* **Supporting Data:**
  * **83.05% of all clean encounters (82,506 / 99,340)** had no HbA1c test recorded in the hospital record (`A1Cresult = 'None'`).
  * Encounters without recorded HbA1c testing had an **11.69% 30-day readmission rate** (9,641 / 82,506).
  * In encounters where HbA1c was measured, readmission rates were:
    * HbA1c > 7: **10.15%** (383 / 3,775 encounters; 3.80% share).
    * HbA1c > 8: **9.94%** (809 / 8,137 encounters; 8.19% share).
    * HbA1c Normal: **9.77%** (481 / 4,922 encounters; 4.95% share).
* **What it might mean:** Inpatient HbA1c testing may be associated with facilities that had standardized diabetic clinical pathways or documented endocrinology consultation protocols in place during this historical period.
* **Limitation:** In-hospital testing might have been omitted if the patient had an outpatient HbA1c lab performed shortly before admission, which cannot be identified in inpatient claims alone.

---

### Finding 5: Repeat Patient Encounters Influence Macro Rates and Age Group Patterns
* **Supporting Data:**
  * In the full clean dataset (99,340 encounters), encounters in the `[20-30)` age group had a **14.31%** readmission rate (236 readmissions / 1,649 encounters).
  * In the single-encounter robustness cohort (`first_encounters`, 69,987 encounters), the readmission rate for the `[20-30)` group was **7.40%** (83 / 1,121).
  * Overall readmission rate was **11.39%** across all encounters and **8.98%** when limited to first encounters.
* **What it might mean:** The `[20-30)` group is relatively small (1,649 encounters in `clean_encounters`, representing 1.66% of the cohort; 1,121 unique patients in `first_encounters`). An untested hypothesis is that a small subset of young patients with frequent recurrent admissions accounted for multiple encounters in this bracket, thereby inflating the encounter-level readmission rate. Deduplication removes this weighting, showing a general pattern of increasing readmission rates with age among adult cohorts (`[60-70)`: 9.02%, `[70-80)`: 10.24%, `[80-90)`: 10.79%).
* **Limitation:** Restricting analysis to first encounters discards information regarding repeated admissions and longitudinal care utilization over time.

---

## Cleaning Decisions Log

The following cleaning operations transformed `raw_encounters` (101,766 rows) into `clean_encounters` (99,340 rows):

| Cleaning Rule | Target Column(s) | Rows Affected | Operational Rationale & Handling |
| :--- | :--- | :--- | :--- |
| **Exclude Expired & Hospice Discharges** | `discharge_disposition_id` in `(11, 13, 14, 19, 20, 21)` | **2,423 rows removed** | Patients who expired in-hospital (`11, 19, 20`) or transferred to hospice (`13, 14`) cannot be readmitted. Retaining them biases the readmission rate denominator downward. |
| **Remove Invalid Gender** | `gender = 'Unknown/Invalid'` | **3 rows removed** | Unimputable demographic noise; 0 overlap with expired/hospice exclusions. |
| **Drop Missing Weight Column** | `weight` | **98,569 rows missing (96.86%)** | Missingness exceeds 96%. Imputing over 96% of data would introduce substantial distortion into analytical models. |
| **Standardize Race Missingness** | `race` | **2,232 rows converted from `'?'` to `NULL` (MySQL) / `'Unknown'` (Tableau)** | In `raw_encounters`, 2,273 rows had `'?'`. 41 were removed during clinical exclusions. In MySQL `clean_encounters`, the remaining 2,232 rows were set to `NULL` via `CASE WHEN race = '?' THEN NULL ELSE race END`. When exported to `outputs/tableau_data.csv`, `COALESCE(race, 'Unknown')` was applied so Tableau displays an explicit `'Unknown'` category with 0 unmapped nulls. |
| **Impute Medical Specialty Missingness** | `medical_specialty` | **48,614 rows converted from `'?'` to `'Unknown'`** | Preserves encounter volume while making missingness explicit for Tableau filtering and CTE rankings. |
| **Binary Readmission Target Engineering** | `readmit_30` | **99,340 rows engineered** | Encoded `1` if `readmitted = '<30'` else `0`. Encounters with `>30` are coded `0` per standard 30-day CMS HRRP definitions. |
| **Inpatient Visit Grouping** | `prior_visits_group` | **99,340 rows engineered** | Binned `number_inpatient` into `'0'`, `'1-2'`, `'3+'` to capture utilization tiers. |

---

## Analytical & Methodological Limitations

1. **Observational Claims Data:** All findings represent statistical associations, **not causal mechanisms**. We cannot conclude that longer stays or specific medications cause readmission.
2. **Historical Dataset Window (1999–2008):** The dataset predates the CMS Hospital Readmissions Reduction Program (established in 2012 under the Affordable Care Act) and modern pharmacological classes (GLP-1 receptor agonists and SGLT2 inhibitors).
3. **Diabetic Patient Restriction:** The cohort consists exclusively of diabetic patients. Findings cannot be generalized to general medical/surgical hospital readmissions.
4. **Repeat Patient Clustering:** 71,518 unique patients generated 101,766 encounters. Encounters from the same patient violate standard regression independence assumptions.
5. **Absence of Social Determinants of Health (SDOH):** Key factors associated with readmission—such as health literacy, transportation access, insurance stability, and pharmacy affordability—are unobserved in administrative claims.

---

## Interview Q&A (Innovaccer Technical & Clinical Questions)

### Q1: Why did you exclude discharge disposition IDs 11, 13, 14, 19, 20, and 21?
> **Answer:** In healthcare analytics, 30-day readmission metrics measure the rate at which eligible discharged patients return to the hospital. Patients who expired during the encounter (IDs 11, 19, 20) or who were discharged to hospice care (IDs 13, 14) are not at risk for readmission. If retained in the denominator, they artificially deflate the measured readmission rate. This aligns strictly with CMS HRRP cohort specifications.

### Q2: How did you handle the missing data denoted by the '?' character in MySQL and Tableau?
> **Answer:** In the raw dataset, missing values were stored as literal string `'?'` characters. For `weight`, profiling revealed 96.86% missingness, so the column was dropped entirely because imputing over 96% would introduce unacceptable bias. For `race`, `'?'` was converted to `NULL` in MySQL `clean_encounters` (2,232 clean rows). When exporting to Tableau, `COALESCE(race, 'Unknown')` was applied so Tableau displays an explicit `'Unknown'` category with 0 unmapped nulls. For `medical_specialty` (49.08% missing in raw data), `'?'` was converted to `'Unknown'`, allowing us to retain the volume while filtering only valid specialties (>= 500 encounters) in clinical rankings.

### Q3: Why did you define readmission strictly as '<30' days rather than including '>30'?
> **Answer:** The primary healthcare quality benchmark under CMS HRRP and commercial value-based care contracts is the **30-day all-cause readmission rate**. Hospital quality committees and payers focus on 30 days because readmissions within that window are considered potentially preventable through quality inpatient care, thorough discharge planning, and post-acute coordination. Readmissions beyond 30 days are generally considered reflections of outpatient disease progression and long-term care management.

### Q4: What did the robustness check on `first_encounters` reveal, and why was it necessary?
> **Answer:** 71,518 unique patients generated 101,766 encounters, meaning repeat utilizers were represented multiple times. Using `ROW_NUMBER() OVER (PARTITION BY patient_nbr ORDER BY encounter_id ASC)`, I isolated each patient's first encounter (69,987 encounters). This revealed that the baseline readmission rate was 8.98% compared to 11.39% in the full encounter dataset, and resolved an apparent spike in the 20–30 age bracket (dropping from 14.31% to 7.40%), suggesting that a small group of repeat utilizers influenced that bracket. Crucially, the gradient for prior inpatient visits remained consistent (a 3.25x ratio for 3+ visits vs 0 visits), confirming prior utilization as a consistent marker across cohorts.

### Q5: What are the limits of this analysis and dashboard for clinical operations?
> **Answer:** This dashboard provides population-level surveillance rather than individual patient clinical risk scoring. It relies on observational claims lacking real-time EHR vitals, bedside nursing notes, and social determinants of health. Additionally, because the data spans 1999–2008, it does not reflect modern diabetic therapies or contemporary value-based care transition programs.
