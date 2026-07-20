import bcrypt
from config import get_db_connection

def setup_test_passwords():
    print("Connecting to database...")
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # The password we want to use for testing
        test_password = "password123"
        hashed_pw = bcrypt.hashpw(test_password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        
        print(f"Updating all user passwords to '{test_password}'...")
        cursor.execute("UPDATE user SET password_hash = %s", (hashed_pw,))
        conn.commit()
        
        print(f"Successfully updated {cursor.rowcount} users!")
        print("You can now log in using any username (e.g., 'admin', 'c_wickramasinghe') and the password 'password123'.")
        
    except Exception as e:
        print(f"Error: {e}")
        print("Make sure your database is running and the schema/seed data is imported!")
    finally:
        if 'conn' in locals() and conn.is_connected():
            cursor.close()
            conn.close()

if __name__ == "__main__":
    setup_test_passwords()
