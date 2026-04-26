import os
from dotenv import load_dotenv
import mysql.connector

load_dotenv()

class Database:
    def __init__(self):
        self.connection = None

    def connect(self):
        if self.connection and self.connection.is_connected():
            return self.connection
        try:
            self.connection = mysql.connector.connect(
                host=os.getenv("DB_HOST"),
                user=os.getenv("DB_USER"),
                password=os.getenv("DB_PASSWORD"),
                database=os.getenv("DB_NAME"),
            )
            if self.connection.is_connected():
                print("✅ Conexión exitosa a MariaDB")
                return self.connection
        except mysql.connector.Error as e:
            print(f"❌ Error al conectar: {e}")
            self.connection = None
            return None

    def close(self):
        if self.connection and self.connection.is_connected():
            self.connection.close()
            print("🔌 Conexión cerrada.")
            self.connection = None

    def __enter__(self):
        return self.connect()

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.connection and self.connection.is_connected():
            # 1. Si no hubo errores, guardamos los cambios
            if exc_type is None:
                self.connection.commit()
                print("Cambios guardados (commit).")
            else:
                self.connection.rollback()
            print("↩Hubo un error, se hizo rollback.")
        
        self.close()
