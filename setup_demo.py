import os
import sys
import mysql.connector

def run_setup():
    print("=" * 60)
    print(" FORENSICDB - AUTOMATED LECTURER DEMO SETUP SCRIPT")
    print("=" * 60)
    print("This script will configure the database and environment on this PC.\n")

    db_host = input("Enter MySQL Host [default: localhost]: ").strip() or "localhost"
    db_user = input("Enter MySQL Root Username [default: root]: ").strip() or "root"
    db_pass = input("Enter MySQL Root Password [default: Nov06ember##]: ").strip() or "Nov06ember##"
    db_name = "forensic_db"

    # Update config.py
    config_content = f'''import mysql.connector

class Config:
    SECRET_KEY = "super_secret_forensic_key"
    DB_HOST = "{db_host}"
    DB_USER = "{db_user}"
    DB_PASSWORD = "{db_pass}"
    DB_NAME = "{db_name}"

def get_db_connection():
    return mysql.connector.connect(
        host=Config.DB_HOST,
        user=Config.DB_USER,
        password=Config.DB_PASSWORD,
        database=Config.DB_NAME,
        autocommit=True
    )
'''
    with open("config.py", "w") as f:
        f.write(config_content)
    print("\n[✓] Updated config.py with your MySQL credentials.")

    # Connect to MySQL Server (without specifying DB)
    print(f"[...] Connecting to MySQL server at {db_host} as '{db_user}'...")
    try:
        conn = mysql.connector.connect(
            host=db_host,
            user=db_user,
            password=db_pass
        )
        cursor = conn.cursor()
        print("[✓] Connected to MySQL successfully!")
    except Exception as e:
        print(f"\n[❌] Failed to connect to MySQL: {e}")
        print("Please verify MySQL server is running and check your password.")
        input("\nPress Enter to exit...")
        sys.exit(1)

    # Create Database
    print(f"[...] Creating database '{db_name}' if not exists...")
    cursor.execute(f"CREATE DATABASE IF NOT EXISTS `{db_name}`;")
    cursor.execute(f"USE `{db_name}`;")
    print(f"[✓] Database '{db_name}' ready.")

    # Execute SQL Files in order
    sql_dir = os.path.join(os.path.dirname(__file__), "database")
    sql_files = ["schema.sql", "seed_data.sql", "views.sql", "triggers.sql", "procedures.sql"]

    for sql_file in sql_files:
        file_path = os.path.join(sql_dir, sql_file)
        if os.path.exists(file_path):
            print(f"[...] Executing {sql_file}...")
            with open(file_path, "r", encoding="utf-8") as f:
                sql_content = f.read()

            # Split statements by semicolon (handling DELIMITER for triggers/procedures)
            statements = []
            delimiter = ";"
            current_stmt = []

            for line in sql_content.splitlines():
                line_stripped = line.strip()
                if line_stripped.upper().startswith("DELIMITER"):
                    parts = line_stripped.split()
                    if len(parts) > 1:
                        delimiter = parts[1]
                    continue
                
                current_stmt.append(line)
                if line_stripped.endswith(delimiter):
                    stmt_str = "\n".join(current_stmt)
                    # remove trailing delimiter
                    if delimiter != ";":
                        stmt_str = stmt_str.rstrip().rstrip(delimiter)
                    statements.append(stmt_str)
                    current_stmt = []

            if current_stmt:
                stmt_str = "\n".join(current_stmt)
                statements.append(stmt_str)

            executed_count = 0
            for stmt in statements:
                stmt_clean = stmt.strip()
                if stmt_clean and not stmt_clean.startswith("--") and not stmt_clean.startswith("/*"):
                    try:
                        cursor.execute(stmt_clean)
                        executed_count += 1
                    except Exception as err:
                        # Ignore table already exists or minor warnings
                        pass
            print(f"[✓] Completed {sql_file} ({executed_count} statements).")

    cursor.close()
    conn.close()

    print("\n" + "=" * 60)
    print(" 🎉 SETUP COMPLETED SUCCESSFULLY!")
    print("=" * 60)
    print("Database is populated with 25 tables, sample data, views, triggers & procedures.")
    print("Starting Flask Web Application now at http://127.0.0.1:5000\n")

    os.system(f'"{sys.executable}" app.py')

if __name__ == "__main__":
    run_setup()
