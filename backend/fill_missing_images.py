import sys
import os

# Asegurar que las importaciones de backend funcionen
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

import mysql.connector
from services.extractor import ExtractorService

def fill_images():
    print("--- Buscando imágenes automáticas para productos cargados ---")
    
    from dotenv import load_dotenv
    load_dotenv()
    
    db_host = os.getenv("DB_HOST", "127.0.0.1")
    db_user = os.getenv("DB_USER", "logw_user")
    db_password = os.getenv("DB_PASSWORD", "logw_password")
    db_name = os.getenv("DB_NAME", "logw_db")
    
    # Conexión local a la base de datos
    conn = mysql.connector.connect(
        host=db_host,
        user=db_user,
        password=db_password,
        database=db_name
    )
    cur = conn.cursor(dictionary=True)
    
    import sys
    force = "--force" in sys.argv
    
    if force:
        print("Modo FORCE activo: Se buscarán y actualizarán las imágenes de TODOS los productos.")
        cur.execute("SELECT id, name, image_url FROM products")
    else:
        print("Buscando productos sin imagen o con imágenes incorrectas (placeholders/default)...")
        cur.execute(
            "SELECT id, name, image_url FROM products "
            "WHERE image_url IS NULL OR image_url = '' OR image_url LIKE '%default_big%' OR image_url LIKE '%/default/%'"
        )
    products = cur.fetchall()
    
    if not products:
        print("No hay productos que requieran actualización de imagen en la base de datos.")
        conn.close()
        return
        
    print(f"Encontrados {len(products)} productos para procesar. Iniciando búsqueda...")
    
    updated_count = 0
    for idx, p in enumerate(products):
        p_id = p['id']
        p_name = p['name']
        
        # Delay de cortesía para evitar bloquearnos con Brave Search
        if idx > 0:
            import time
            time.sleep(3.5)
            
        print(f"\nBuscando para: '{p_name}'...")
        
        try:
            image_url = ExtractorService.search_image(p_name)
            if image_url:
                print(f"¡Imagen encontrada!: {image_url}")
                # Actualizar base de datos
                update_cur = conn.cursor()
                update_cur.execute(
                    "UPDATE products SET image_url = %s WHERE id = %s",
                    (image_url, p_id)
                )
                conn.commit()
                print(f"Producto ID {p_id} actualizado en la base de datos.")
                updated_count += 1
            else:
                print("No se encontró ninguna imagen en internet para este producto.")
        except Exception as e:
            print(f"Error procesando '{p_name}': {e}")
            
    print(f"\n--- Proceso completado. Se actualizaron {updated_count} productos. ---")
    conn.close()

if __name__ == "__main__":
    fill_images()
