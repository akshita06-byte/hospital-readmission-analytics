import os
import pandas as pd
import pymysql
from dotenv import load_dotenv

load_dotenv()

DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_PORT = int(os.getenv('DB_PORT', 3306))
DB_USER = os.getenv('DB_USER', 'root')
DB_PASSWORD = os.getenv('DB_PASSWORD', '')
DB_NAME = os.getenv('DB_NAME', 'hospital_analytics')

def run_analysis_and_export():
    outputs_dir = os.path.join(os.path.dirname(__file__), 'outputs')
    os.makedirs(outputs_dir, exist_ok=True)
    
    conn = pymysql.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        charset='utf8mb4',
        cursorclass=pymysql.cursors.DictCursor
    )
    
    queries = {
        '01_overall_rate': """
            SELECT 
                COUNT(*) AS total_encounters,
                SUM(readmit_30) AS readmissions_30_days,
                ROUND(AVG(readmit_30) * 100, 2) AS readmission_rate_pct,
                ROUND(AVG(time_in_hospital), 2) AS avg_length_of_stay,
                ROUND(AVG(num_medications), 2) AS avg_num_medications
            FROM clean_encounters;
        """,
        '02_rate_by_age': """
            SELECT 
                age,
                COUNT(*) AS total_encounters,
                SUM(readmit_30) AS readmissions_30,
                ROUND(AVG(readmit_30) * 100, 2) AS readmission_rate_pct,
                ROUND(AVG(time_in_hospital), 2) AS avg_length_of_stay
            FROM clean_encounters
            GROUP BY age
            ORDER BY age;
        """,
        '03_rate_by_prior_visits': """
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
        """,
        '04_rate_by_los': """
            SELECT 
                time_in_hospital AS los_days,
                COUNT(*) AS total_encounters,
                SUM(readmit_30) AS readmissions_30,
                ROUND(AVG(readmit_30) * 100, 2) AS readmission_rate_pct
            FROM clean_encounters
            GROUP BY time_in_hospital
            ORDER BY time_in_hospital ASC;
        """,
        '05_rate_by_specialty': """
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
        """,
        '06_rate_by_a1c': """
            SELECT 
                A1Cresult,
                COUNT(*) AS total_encounters,
                SUM(readmit_30) AS readmissions_30,
                ROUND(AVG(readmit_30) * 100, 2) AS readmission_rate_pct,
                ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM clean_encounters), 2) AS cohort_share_pct
            FROM clean_encounters
            GROUP BY A1Cresult
            ORDER BY readmission_rate_pct DESC;
        """,
        '07_rate_by_medications': """
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
        """,
        '08a_rate_by_gender': """
            SELECT 
                gender,
                COUNT(*) AS total_encounters,
                SUM(readmit_30) AS readmissions_30,
                ROUND(AVG(readmit_30) * 100, 2) AS readmission_rate_pct
            FROM clean_encounters
            GROUP BY gender
            ORDER BY readmission_rate_pct DESC;
        """,
        '08b_rate_by_race': """
            SELECT 
                COALESCE(race, 'Missing / Unspecified') AS race,
                COUNT(*) AS total_encounters,
                SUM(readmit_30) AS readmissions_30,
                ROUND(AVG(readmit_30) * 100, 2) AS readmission_rate_pct,
                ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM clean_encounters), 2) AS share_of_encounters_pct
            FROM clean_encounters
            GROUP BY race
            ORDER BY total_encounters DESC;
        """,
        '09a_first_encounters_overall': """
            SELECT 
                'first_encounters' AS cohort,
                COUNT(*) AS total_encounters,
                SUM(readmit_30) AS readmissions_30,
                ROUND(AVG(readmit_30) * 100, 2) AS readmission_rate_pct,
                ROUND(AVG(time_in_hospital), 2) AS avg_length_of_stay,
                ROUND(AVG(num_medications), 2) AS avg_num_medications
            FROM first_encounters;
        """,
        '09b_first_encounters_by_age': """
            SELECT 
                age,
                COUNT(*) AS total_encounters,
                SUM(readmit_30) AS readmissions_30,
                ROUND(AVG(readmit_30) * 100, 2) AS readmission_rate_pct
            FROM first_encounters
            GROUP BY age
            ORDER BY age;
        """,
        '09c_first_encounters_by_prior_visits': """
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
        """
    }
    
    print("=== RUNNING ANALYSIS QUERIES AND EXPORTING CSVs ===")
    for name, sql in queries.items():
        with conn.cursor() as cursor:
            cursor.execute(sql)
            rows = cursor.fetchall()
            df = pd.DataFrame(rows)
            out_path = os.path.join(outputs_dir, f"{name}.csv")
            df.to_csv(out_path, index=False, encoding='utf-8')
            print(f"\n--- {name} ({len(df)} rows) -> saved to {out_path} ---")
            print(df.to_string(index=False))
            
    print("\n=== EXPORTING TABLEAU DATASET (clean_encounters) ===")
    tableau_sql = """
        SELECT 
            encounter_id,
            patient_nbr,
            COALESCE(race, 'Unknown') AS race,
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
        FROM clean_encounters
        ORDER BY encounter_id;
    """
    with conn.cursor() as cursor:
        cursor.execute(tableau_sql)
        rows = cursor.fetchall()
        df_tableau = pd.DataFrame(rows)
        tableau_out = os.path.join(outputs_dir, "tableau_data.csv")
        df_tableau.to_csv(tableau_out, index=False, encoding='utf-8')
        print(f"Exported tableau_data.csv successfully!")
        print(f"Shape: {df_tableau.shape}")
        print(f"Columns: {list(df_tableau.columns)}")
        print(f"File size: {os.path.getsize(tableau_out):,} bytes")
        print("Sample head:")
        print(df_tableau.head(3).to_string(index=False))
        
    conn.close()

if __name__ == '__main__':
    run_analysis_and_export()
