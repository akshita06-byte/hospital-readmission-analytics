# Tableau Public Build Guide: Hospital 30-Day Readmission Analytics

**Author:** Data Analyst Intern Candidate  
**Project:** Hospital Readmission Analytics Dashboard  
**Data Source:** `hospital-readmission-analytics/outputs/tableau_data.csv` (99,340 rows, 9.15 MB)  
**Target Tableau Canvas Size:** Fixed Size 1200 x 800 px  

---

## 1. Connecting to the Clean Dataset

1. Open **Tableau Desktop Public Edition** (or Tableau Desktop).
2. On the left start pane under **To a File**, click **Text file**.
3. Browse to and select:  
   `hospital-readmission-analytics/outputs/tableau_data.csv`
4. In the Data Source preview window:
   * Verify that **99,340 rows** and **18 columns** are loaded.
   * Verify data types:
     * `encounter_id`: Number (whole) / Dimension
     * `patient_nbr`: Number (whole) / Dimension
     * `race`: String (with 'Unknown' representing unrecorded race, 0 nulls)
     * `gender`: String
     * `age`: String
     * `time_in_hospital`: Number (whole)
     * `medical_specialty`: String
     * `num_lab_procedures`: Number (whole)
     * `num_medications`: Number (whole)
     * `prior_visits_group`: String
     * `A1Cresult`: String ('None', '>7', '>8', 'Norm')
     * `readmit_30`: Number (whole)
5. Click **Sheet 1** at the bottom left to enter the workspace.

---

## 2. Creating Core Calculated Fields

Create these 4 calculated fields by clicking the small triangle arrow at the top of the **Data Pane** -> **Create Calculated Field**:

### 1. `Readmission Rate`
* **Formula:**
  ```tableau
  AVG([readmit_30])
  ```
* **Default Number Formatting:** Right-click `Readmission Rate` in Data Pane -> **Default Properties** -> **Number Format...** -> Select **Percentage**, set **Decimal places = 1** (displays as `11.4%`).

### 2. `Total Encounters`
* **Formula:**
  ```tableau
  COUNT([encounter_id])
  ```
* **Default Number Formatting:** Right-click `Total Encounters` -> **Default Properties** -> **Number Format...** -> Select **Number (Standard)** or **Number (Custom)** with thousands separator enabled (displays as `99,340`).

### 3. `Avg Length of Stay`
* **Formula:**
  ```tableau
  AVG([time_in_hospital])
  ```
* **Default Number Formatting:** Right-click `Avg Length of Stay` -> **Default Properties** -> **Number Format...** -> Select **Number (Custom)**, set **Decimal places = 1**, Suffix = ` days` (displays as `4.4 days`).

### 4. `Avg Medications`
* **Formula:**
  ```tableau
  AVG([num_medications])
  ```
* **Default Number Formatting:** Right-click `Avg Medications` -> **Default Properties** -> **Number Format...** -> Select **Number (Custom)**, set **Decimal places = 1** (displays as `16.0`).

---

## 3. Building Individual Sheets (Click-by-Click)

### Sheet 1: `KPI_Total_Encounters`
1. Rename Sheet to `KPI_Total_Encounters`.
2. Drag `Total Encounters` onto the **Text** card on the Marks card.
3. Click **Text** card -> Click the `...` button next to Text.
4. Format font: Set `[Total Encounters]` to **22pt, Bold, Dark Slate Blue (`#1E293B`)**.
5. Add label text above: `TOTAL ENCOUNTERS` in **9pt, Regular, Gray (`#64748B`)**.
6. Set Alignment to **Center / Middle**.
7. Right-click the worksheet canvas -> **Format...** -> Shading: Light Gray / Subtle Off-White (`#F8FAFC`).

### Sheet 2: `KPI_Readmission_Rate`
1. Duplicate Sheet 1, rename to `KPI_Readmission_Rate`.
2. Replace text measure with `Readmission Rate`.
3. Format font: Set `[Readmission Rate]` to **22pt, Bold, Crimson Red / Coral (`#DC2626`)**.
4. Label above: `30-DAY READMISSION RATE` in **9pt, Regular, Gray (`#64748B`)**.

### Sheet 3: `KPI_Avg_LOS`
1. Duplicate Sheet 1, rename to `KPI_Avg_LOS`.
2. Replace text measure with `Avg Length of Stay`.
3. Format font: Set to **22pt, Bold, Navy Blue (`#0F172A`)**.
4. Label above: `AVG LENGTH OF STAY` in **9pt, Regular, Gray (`#64748B`)**.

### Sheet 4: `KPI_Avg_Medications`
1. Duplicate Sheet 1, rename to `KPI_Avg_Medications`.
2. Replace text measure with `Avg Medications`.
3. Format font: Set to **22pt, Bold, Navy Blue (`#0F172A`)**.
4. Label above: `AVG MEDICATIONS / ENCOUNTER` in **9pt, Regular, Gray (`#64748B`)**.

---

### Sheet 5: `Rate_by_Prior_Visits`
1. Rename Sheet to `Rate_by_Prior_Visits`.
2. Drag `prior_visits_group` to **Columns**.
3. Drag `Readmission Rate` to **Rows**.
4. On the Marks card, select **Bar**.
5. Ensure sort order on Columns: Right-click `prior_visits_group` pill -> **Sort...** -> Manual sort: `'0'`, `'1-2'`, `'3+'`.
6. Drag `Readmission Rate` onto the **Color** card.
   * Choose color palette: **Orange-Blue Diverging** or **Sequential Red / Blue** (e.g., Slate Blue `#3B82F6` to Deep Red `#EF4444`).
7. Drag `Readmission Rate` onto the **Label** card.
   * Set label position to **Top Center** outside bars.
8. Drag `Total Encounters` onto **Tooltip**.
9. Customize Tooltip:
   ```text
   Prior Inpatient Visits: <prior_visits_group>
   Readmission Rate: <AGG(Readmission Rate)>
   Total Encounters: <AGG(Total Encounters)>
   ```
10. Hide vertical axis title (Right-click axis -> uncheck **Show Header**).
11. Rename bottom axis to `Prior Inpatient Hospitalizations`.
12. Set worksheet title to: `30-Day Readmission Rate by Prior Inpatient Visits`.

---

### Sheet 6: `Rate_by_Age_Group`
1. Rename Sheet to `Rate_by_Age_Group`.
2. Drag `age` to **Columns**.
3. Drag `Readmission Rate` to **Rows**.
4. Set Mark type to **Bar**.
5. Ensure chronological sort: `[0-10)`, `[10-20)`, `[20-30)`, `...`, `[90-100)`.
6. Drag `Readmission Rate` to **Color** (use consistent monochromatic blue or teal palette `#0284C7`).
7. Drag `Readmission Rate` to **Label** (Show mark labels, 8pt, bold).
8. Drag `Total Encounters` and `Avg Length of Stay` to **Tooltip**.
9. Remove vertical grid lines, clean horizontal axis headers.
10. Title: `30-Day Readmission Rate by Age Cohort`.

---

### Sheet 7: `Top_Specialties_Ranked`
1. Rename Sheet to `Top_Specialties_Ranked`.
2. Drag `medical_specialty` to **Rows**.
3. Drag `Readmission Rate` to **Columns**.
4. Mark type: **Horizontal Bar**.
5. **Volume Filter (>= 500 Encounters):**
   * Drag `Total Encounters` to the **Filters** shelf.
   * Choose **At least**, enter `500`. Click OK.
6. **Exclude Unknown Specialty:**
   * Drag `medical_specialty` to the **Filters** shelf.
   * Uncheck `Unknown`. Click OK.
7. Sort bars: Click the sort descending icon on the toolbar (or right-click `medical_specialty` on Rows -> Sort by Field `Readmission Rate` descending).
8. **Top 10 Filter:**
   * Right-click `medical_specialty` filter on Filters shelf -> **Edit Filter...** -> Go to the **Top** tab.
   * Select **By field** -> **Top 10** by `Readmission Rate` (Aggregation: `Average`). Click OK.
9. Drag `Readmission Rate` to **Label** and **Color**.
10. Title: `Top 10 Clinical Specialties by Readmission Rate (Min. 500 Encounters)`.

---

### Sheet 8: `Rate_by_Length_of_Stay`
1. Rename Sheet to `Rate_by_Length_of_Stay`.
2. Drag `time_in_hospital` to **Columns** (ensure it is treated as Continuous or Discrete dimension 1–14).
3. Drag `Readmission Rate` to **Rows**.
4. Set Mark type to **Line** (or **Bar**).
   * If Line: Add circle marks (Marks card -> Color -> Marker: Show).
5. Drag `Readmission Rate` to **Label** (Label min/max or all marks).
6. Drag `Total Encounters` to **Tooltip**.
7. Color: Deep Navy Blue (`#1E3A8A`).
8. Title: `Readmission Rate by Length of Hospital Stay (Days 1–14)`.

---

## 4. Assembling the Final Dashboard (1200 x 800 px)

1. Click **New Dashboard** icon at bottom.
2. In the left panel under **Size**:
   * Change from *Range* to **Fixed size**.
   * Width: `1200 px`, Height: `800 px`.
3. Set dashboard background to Clean Light Gray (`#F1F5F9`).

### Layout Hierarchy:
* **Header Container (Vertical, Top):**
  * **Title:** `Clinical Inpatient Readmission Surveillance` (20pt Bold, `#0F172A`).
  * **Subtitle:** `Analysis of 99,340 US diabetic inpatient encounters (1999–2008) evaluating factors associated with 30-day all-cause readmissions` (10pt Regular, `#475569`).
  * Subtitle note: *30-Day Readmission Rate = % of acute hospital discharges followed by unplanned inpatient readmission within 30 days.*

* **KPI Container (Horizontal, Height ~90 px):**
  * Arrange `KPI_Total_Encounters`, `KPI_Readmission_Rate`, `KPI_Avg_LOS`, and `KPI_Avg_Medications` side-by-side with subtle borders / padding.

* **Main Analytical Grid (2x2 Layout):**
  * **Top-Left (Width 55%):** `Rate_by_Prior_Visits`
  * **Top-Right (Width 45%):** `Rate_by_Age_Group`
  * **Bottom-Left (Width 55%):** `Top_Specialties_Ranked`
  * **Bottom-Right (Width 45%):** `Rate_by_Length_of_Stay`

* **Interactive Filter Bar:**
  * Add filters for: `age`, `gender`, `medical_specialty`.
  * **CRITICAL STEP:** Configure filters to apply globally across all worksheets:
    * Click the small dropdown arrow on each filter card -> **Apply to Worksheets** -> **Selected Worksheets...** -> Select all sheets on this dashboard (or *All Using Related Data Sources*).
  * Format filters as **Multiple Values (dropdown)** for clean canvas layout.

* **Footer Notes (Text Box at bottom, Height ~40 px):**
  * Text:
    ```text
    Data Source: Diabetes 130-US Hospitals (1999–2008), UCI Machine Learning Repository. Observational claims data; correlations do not imply clinical causation. Excluded in-hospital mortality and hospice transfers (discharge codes 11, 13, 14, 19, 20, 21) per CMS HRRP benchmarking methodology.
    ```
    (8pt Italic, `#64748B`).

---

## 5. Publishing to Tableau Public

1. In Tableau Public Desktop, click **File** -> **Save to Tableau Public As...**
2. Enter your Tableau Public login credentials (create a free account at `public.tableau.com` if you do not have one).
3. Name the workbook: `Hospital-Readmission-Analytics-Innovaccer`.
4. Wait for upload to complete; your browser will automatically open the published dashboard URL.
5. In your browser on Tableau Public:
   * Click **Edit Details**.
   * Toggle **Allow access to workbook and its data** (so interviewers can review calculated fields).
   * Click **Share** (bottom right) -> Copy the **Link** (e.g., `https://public.tableau.com/views/Hospital-Readmission-Analytics-Innovaccer/Dashboard1`).
   * Paste this link into `README.md`.

---

## 6. Common Mistakes Checklist (Interview Quality Check)

| Check Item | Common Error | How to Fix |
| :--- | :--- | :--- |
| **Percentage Formatting** | Showing decimals (`0.1139`) instead of percent (`11.4%`) | Format `Readmission Rate` default properties as Percentage with 1 decimal. |
| **Categorical Sorting** | Prior visits showing `'1-2'`, `'3+'`, `'0'` alphabetically | Right-click `prior_visits_group` on shelf -> Sort -> Manual sort `'0'`, `'1-2'`, `'3+'`. |
| **Dual Axes Overlap** | Combining rates and counts on conflicting axes | Keep KPI cards separate; use tooltips to supply context volume instead of cluttered dual axes. |
| **Specialty Volume Noise** | Specialties with 1 encounter showing 100% readmission | Filter `Total Encounters` >= 500 to ensure adequate volume. |
| **Palette Proliferation** | Using rainbow colors across charts | Use a cohesive two-tone palette (Slate Blue `#1E293B` and Clinical Red/Teal accents). |
| **Unlinked Filters** | Filter on Age only updating one chart | Set filter -> Apply to Worksheets -> All Using This Data Source. |
