import os
import mysql.connector
from dotenv import load_dotenv

def init_db():
    load_dotenv()
    
    try:
        print("Conectando a la base de datos...")
        conn = mysql.connector.connect(
            host=os.getenv("DB_HOST"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD"),
            database=os.getenv("DB_NAME"),
            port=os.getenv("DB_PORT", 3306)
        )
        cursor = conn.cursor()

        print("Leyendo archivo SQL...")
        sql_path = os.path.join("database_docs", "database.sql")
        with open(sql_path, "r", encoding="utf-8") as f:
            sql_commands = f.read().split(';')

        print("Ejecutando comandos...")
        for command in sql_commands:
            if command.strip():
                try:
                    cursor.execute(command)
                except mysql.connector.Error as err:
                    print(f"Error en comando: {err}")

        conn.commit()
        print("¡Base de datos inicializada con éxito!")
        
        cursor.close()
        conn.close()
    except Exception as e:
        print(f"Error crítico: {e}")

if __name__ == "__main__":
    init_db()
