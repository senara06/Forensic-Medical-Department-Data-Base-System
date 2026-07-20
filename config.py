import mysql.connector

class Config:
    SECRET_KEY = "super_secret_forensic_key"
    DB_HOST = "localhost"
    DB_USER = "root"
    DB_PASSWORD = "12345"
    DB_NAME = "forensic_db"

def get_db_connection():
    return mysql.connector.connect(
        host=Config.DB_HOST,
        user=Config.DB_USER,
        password=Config.DB_PASSWORD,
        database=Config.DB_NAME,
        autocommit=True
    )
