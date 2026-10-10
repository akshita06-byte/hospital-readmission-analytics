import os
import sys
import pandas as pd
import pymysql
from dotenv import load_dotenv

load_dotenv()

DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_PORT = int(os.getenv('DB_PORT', 3306))
DB_USER = os.getenv('DB_USER', 'root')
DB_PASSWORD = os.getenv('DB_PASSWORD', '')
DB_NAME = os.getenv('DB_NAME', 'hospital_analytics')

def execute_sql_file(sql_file_path):
    conn = pymysql.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        autocommit=True
    )
    cursor = conn.cursor()
    
    with open(sql_file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    queries = [q.strip() for q in content.split(';') if q.strip()]
    
    print(f"=== Executing {sql_file_path} ({len(queries)} statements) ===")
    
    for idx, q in enumerate(queries, 1):
        lines = [line for line in q.splitlines() if not line.strip().startswith('--')]
        clean_q = '\n'.join(lines).strip()
        if not clean_q:
            continue
        if clean_q.upper().startswith('USE '):
            cursor.execute(clean_q)
            continue
            
        print(f"\n--- Statement {idx} ---")
        comments = [line.strip() for line in q.splitlines() if line.strip().startswith('--')]
        if comments:
            print('\n'.join(comments[:3]))
        
        try:
            cursor.execute(clean_q)
            if cursor.description:
                cols = [desc[0] for desc in cursor.description]
                rows = cursor.fetchall()
                df = pd.DataFrame(rows, columns=cols)
                print(f"Result ({len(df)} rows):")
                print(df.to_string(index=False))
            else:
                print(f"Query OK, {cursor.rowcount} rows affected.")
        except Exception as e:
            print(f"Error executing statement {idx}: {e}")
            raise e
            
    cursor.close()
    conn.close()

if __name__ == '__main__':
    if len(sys.argv) > 1:
        execute_sql_file(sys.argv[1])
    else:
        print("Usage: python run_sql.py <path_to_sql_file>")
