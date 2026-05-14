import mysql.connector
from mysql.connector import Error as MySQLError
import os
from dotenv import load_dotenv

load_dotenv()

class Database:
    def __init__(self):
        self.host = os.getenv("DB_HOST", "localhost")
        self.user = os.getenv("DB_USER", "root")
        self.password = os.getenv("DB_PASSWORD", "root")
        self.database = os.getenv("DB_NAME", "logW_DB")
        self.conn = None

    def connect(self):
        try:
            self.conn = mysql.connector.connect(
                host=self.host,
                user=self.user,
                password=self.password,
                database=self.database
            )
            return self.conn
        except MySQLError as e:
            print(f"Error conectando a MySQL: {e}")
            return None

    def close(self):
        if self.conn and self.conn.is_connected():
            self.conn.close()
