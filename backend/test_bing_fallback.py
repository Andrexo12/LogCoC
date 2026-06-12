import requests
import re
import urllib.parse
import html

def clean_brand(query):
    # Remover marcas comunes que suelen activar widgets de compras de Bing
    for brand in ["samsung galaxy", "samsung", "apple", "xiaomi", "huawei", "motorola"]:
        query_lower = query.lower()
        if query_lower.startswith(brand):
            query = query[len(brand):].strip()
        elif brand in query_lower:
            # Reemplazar la palabra si está en el medio
            query = re.sub(r'\b' + re.escape(brand) + r'\b', '', query, flags=re.IGNORECASE).strip()
    # Limpiar espacios dobles
    query = re.sub(r'\s+', ' ', query)
    return query

def search_bing_image(query):
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36"
    }
    
    # Lista de variaciones de consulta a probar en secuencia
    variations = [
        query,                                 # 1. Consulta original
        clean_brand(query),                   # 2. Sin la marca (ej. "S24 Ultra" o "iPhone 15 Pro")
        f"{clean_brand(query)} png",          # 3. Sin marca + png
        f"{query} png",                       # 4. Original + png
        f"{query} photo"                      # 5. Original + photo
    ]
    
    print(f"\n[Buscando Imagen] Consulta Inicial: '{query}'")
    for var in variations:
        if not var or var.strip() == "":
            continue
            
        print(f" -> Probando consulta: '{var}'...")
        encoded = urllib.parse.quote(var)
        url = f"https://www.bing.com/images/search?q={encoded}"
        try:
            r = requests.get(url, headers=headers, timeout=8)
            if r.status_code == 200:
                decoded_html = html.unescape(r.text)
                matches = re.findall(r'"murl"\s*:\s*"([^"]+)"', decoded_html)
                
                # Filtrar enlaces que sean de redes sociales o no parezcan imágenes reales de producto
                valid_matches = []
                for m in matches:
                    m_lower = m.lower()
                    # Ignorar avatars, perfiles, banners o trackers
                    if any(x in m_lower for x in ["facebook", "avatar", "profile", "banner", "tracker", "logo", "icon", "advertisement"]):
                        continue
                    # Priorizar imágenes reales
                    if any(m_lower.endswith(ext) or ext in m_lower for ext in ['.jpg', '.jpeg', '.png', '.webp']):
                        valid_matches.append(m)
                        
                print(f"    * Encontrados {len(matches)} matches en total ({len(valid_matches)} válidos)")
                
                # Si encontramos suficientes resultados orgánicos, tomamos el primero válido
                if len(valid_matches) >= 5:
                    print(f"    * ¡Éxito con '{var}'!: {valid_matches[0]}")
                    return valid_matches[0]
                elif len(matches) >= 5:
                    print(f"    * Éxito parcial: {matches[0]}")
                    return matches[0]
        except Exception as e:
            print(f"    * Error en variación '{var}': {e}")
            
    # Si todo falla, devolver el primer match que encontremos con la consulta original (aunque sea 1 solo)
    print(" -> Fallback: Buscando cualquier primer resultado de la consulta original...")
    try:
        encoded = urllib.parse.quote(query)
        url = f"https://www.bing.com/images/search?q={encoded}"
        r = requests.get(url, headers=headers, timeout=8)
        decoded_html = html.unescape(r.text)
        matches = re.findall(r'"murl"\s*:\s*"([^"]+)"', decoded_html)
        if matches:
            return matches[0]
    except:
        pass
        
    return None

if __name__ == "__main__":
    products = [
        "Xiaomi Redmi Note 13",
        "Apple iPhone 15 Pro",
        "Samsung Galaxy S24 Ultra",
        "Xiaomi watch 5 lite"
    ]
    for p in products:
        img = search_bing_image(p)
        print(f"RESULTADO FINAL para '{p}': {img}")
