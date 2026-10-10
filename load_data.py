import os
import re
import sys
import time
import pandas as pd
import pymysql
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_PORT = int(os.getenv('DB_PORT', 3306))
DB_USER = os.getenv('DB_USER', 'root')
DB_PASSWORD = os.getenv('DB_PASSWORD', '')
DB_NAME = os.getenv('DB_NAME', 'hospital_analytics')

def setup_and_load():
    csv_path = os.path.join(os.path.dirname(__file__), 'data', 'diabetic_data.csv')
    mapping_path = os.path.join(os.path.dirname(__file__), 'data', 'IDs_mapping.csv')
    
    if not os.path.exists(csv_path) or not os.path.exists(mapping_path):
        print(f"Error: Data files missing. Please ensure diabetic_data.csv and IDs_mapping.csv exist in data/.")
        sys.exit(1)
        
    print(f"Connecting to MySQL ({DB_USER}@{DB_HOST}:{DB_PORT})...")
    conn = pymysql.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        autocommit=True
    )
    cursor = conn.cursor()
    
    print(f"Creating database {DB_NAME}...")
    cursor.execute(f"DROP DATABASE IF EXISTS `{DB_NAME}`;")
    cursor.execute(f"CREATE DATABASE `{DB_NAME}`;")
    cursor.execute(f"USE `{DB_NAME}`;")
    
    # 1. Parse IDs_mapping.csv
    print("Parsing IDs_mapping.csv...")
    with open(mapping_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    sections = [s.strip() for s in content.split('\n\n') if s.strip()]
    if len(sections) < 3:
        sections = [s.strip() for s in re.split(r'\r?\n\s*,\s*\r?\n', content) if s.strip()]

    for sec in sections:
        lines = [line.strip() for line in sec.splitlines() if line.strip()]
        if not lines:
            continue
        header = lines[0].split(',')
        id_col = header[0].strip()
        
        table_name = id_col.replace('_id', '_lookup')
        cursor.execute(f"DROP TABLE IF EXISTS `{table_name}`;")
        cursor.execute(f"""
            CREATE TABLE `{table_name}` (
                `{id_col}` INT NOT NULL,
                `description` VARCHAR(255),
                PRIMARY KEY (`{id_col}`)
            );
        """)
        
        insert_rows = []
        for line in lines[1:]:
            parts = line.split(',', 1)
            if len(parts) == 2 and parts[0].strip().isdigit():
                val_id = int(parts[0].strip())
                desc = parts[1].strip().strip('"').strip("'")
                insert_rows.append((val_id, desc))
        
        cursor.executemany(
            f"INSERT INTO `{table_name}` (`{id_col}`, `description`) VALUES (%s, %s);",
            insert_rows
        )
        print(f"Loaded {len(insert_rows)} rows into `{table_name}`.")
        
    # 2. Load diabetic_data.csv into raw_encounters
    print("Reading diabetic_data.csv (preserving 'None' string values)...")
    # keep_default_na=False ensures 'None' in clinical test columns (e.g., A1Cresult) is not coerced to NaN
    df = pd.read_csv(csv_path, dtype=str, keep_default_na=False)
    
    print(f"Dataset shape: {df.shape}")
    
    columns = list(df.columns)
    col_defs = []
    for col in columns:
        if col in ['encounter_id', 'patient_nbr', 'admission_type_id', 'discharge_disposition_id', 
                    'admission_source_id', 'time_in_hospital', 'num_lab_procedures', 'num_procedures', 
                    'num_medications', 'number_outpatient', 'number_emergency', 'number_inpatient', 'number_diagnoses']:
            col_defs.append(f"`{col}` INT")
        else:
            col_defs.append(f"`{col}` VARCHAR(100)")
            
    cursor.execute("DROP TABLE IF EXISTS raw_encounters;")
    cursor.execute(f"""
        CREATE TABLE raw_encounters (
            {', '.join(col_defs)},
            PRIMARY KEY (encounter_id)
        );
    """)
    print("Created raw_encounters table.")
    
    # Batch insert
    insert_sql = f"INSERT INTO raw_encounters (`{'`, `'.join(columns)}`) VALUES ({', '.join(['%s']*len(columns))});"
    
    records = []
    for row in df.itertuples(index=False):
        row_vals = []
        for col_name, val in zip(columns, row):
            if col_name in ['encounter_id', 'patient_nbr', 'admission_type_id', 'discharge_disposition_id', 
                            'admission_source_id', 'time_in_hospital', 'num_lab_procedures', 'num_procedures', 
                            'num_medications', 'number_outpatient', 'number_emergency', 'number_inpatient', 'number_diagnoses']:
                try:
                    row_vals.append(int(val))
                except:
                    row_vals.append(None)
            else:
                row_vals.append(str(val))
        records.append(tuple(row_vals))
        
    print("Inserting rows in batches of 5000...")
    batch_size = 5000
    start_time = time.time()
    for i in range(0, len(records), batch_size):
        cursor.executemany(insert_sql, records[i:i+batch_size])
    print(f"Inserted {len(records)} rows in {time.time() - start_time:.2f} seconds.")
    
    cursor.execute("SELECT COUNT(*) FROM raw_encounters;")
    count = cursor.fetchone()[0]
    print(f"Verification: raw_encounters total row count = {count}")
    
    cursor.close()
    conn.close()

if __name__ == '__main__':
    setup_and_load()
