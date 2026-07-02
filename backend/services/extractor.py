import io
import os
import json
import base64
import logging
from typing import List, Dict, Any
import openpyxl
from groq import Groq

logger = logging.getLogger(__name__)

class ExtractorService:
    @staticmethod
    def _clean_product_name_for_search(name: str) -> str:
        import re
        query = name
        # Limpiar volumen y tamaño (ej: 100ml, 100 ml, 3.4 oz, 3.4oz)
        query = re.sub(r'\b\d+\s*(?:ml|oz)\b', '', query, flags=re.IGNORECASE).strip()
        # Limpiar concentraciones y tipos comunes (ej: eau de parfum, edp, etc.)
        query = re.sub(r'\b(?:eau de parfum|eau de toilette|edp|edt|parfum|fragrance|eau de cologne|cologne|eau|toilette)\b', '', query, flags=re.IGNORECASE).strip()
        # Limpiar símbolos como guiones y espacios múltiples
        query = re.sub(r'[-\s_]+', ' ', query).strip()
        return query

    @staticmethod
    def _clean_brand(query: str) -> str:
        # Remover marcas comunes que suelen activar widgets de compras de Bing
        for brand in ["samsung galaxy", "samsung", "apple", "xiaomi", "redmi", "huawei", "motorola"]:
            query_lower = query.lower()
            if query_lower.startswith(brand):
                query = query[len(brand):].strip()
            elif brand in query_lower:
                import re
                query = re.sub(r'\b' + re.escape(brand) + r'\b', '', query, flags=re.IGNORECASE).strip()
        import re
        query = re.sub(r'\s+', ' ', query)
        return query

    @staticmethod
    def _score_image_url(url: str, product_name: str) -> int:
        import re
        url_lower = url.lower()
        
        # Limpiar el nombre para buscar palabras clave significativas
        cleaned_name = ExtractorService._clean_product_name_for_search(product_name)
        
        stopwords = {
            "de", "del", "el", "la", "los", "las", "un", "una", "y", "o",
            "in", "on", "at", "for", "with", "by", "of", "to", "and", "the", "a", "an",
            "edp", "edt", "ml", "oz", "parfum", "toilette", "eau", "cologne", "fragrance"
        }
        product_words = [
            w.lower() for w in cleaned_name.split()
            if (len(w) >= 2 or w.isdigit()) and w.lower() not in stopwords
        ]
        
        score = 0
        
        # Si la marca (primera palabra relevante) está en la URL, subir puntaje
        brand = product_words[0] if product_words else ""
        if brand and brand in url_lower:
            score += 15
            
        # 1. Dominios preferidos de e-commerce y catálogos oficiales (Puntaje positivo alto)
        preferred_domains = [
            "fragrantica.com", "fimgs.net", "perfume", "fragrance", "belleza", "beauty",
            "amazon.com", "media-amazon.com", "ssl-images-amazon.com",
            "kimovil.com", "gsmarena.com", "mlstatic.com", "mercadolibre.com",
            "shopdunk.com", "apple.com", "samsung.com", "xiaomi.com", "mi.com",
            "tienda", "store", "comprar", "shop", "catalogo", "catalog", "mercado"
        ]
        is_trusted_domain = any(domain in url_lower for domain in preferred_domains)
        if is_trusted_domain:
            score += 20
            
        # 2. Palabras clave de imágenes limpias de producto
        clean_keywords = ["png", "transparent", "transparente", "render", "official", "oficial", "stock", "white", "blanco"]
        if any(kw in url_lower for kw in clean_keywords):
            score += 5
            
        # 3. Contener palabras del nombre del producto (muy importante para evitar comparativas cruzadas)
        matched_words = 0
        for word in product_words:
            if word.isdigit():
                # Si el término es numérico (ej. "5", "13"), asegurar que no sea parte de otro número más largo en la URL (ej. "0005" o "421219")
                if re.search(r'(?<!\d)' + re.escape(word) + r'(?!\d)', url_lower):
                    matched_words += 1
            else:
                # Para palabras de texto, basta con que estén presentes en la URL
                if word in url_lower:
                    matched_words += 1
        
        score += matched_words * 10
        
        # Si no contiene ninguna palabra del producto, penalizar fuertemente
        if matched_words == 0:
            score -= 40
            
        # Evitar imágenes que contengan "default" en el path con números (como miniaturas genéricas de kimovil sin modelo)
        if "/default/" in url_lower and matched_words == 0:
            score -= 30
        
        # 4. Dominios prohibidos/blacklisted (Puntaje negativo alto)
        blacklisted = [
            "dxomark", "youtube", "ytimg", "pinterest", "pinimg", "blogspot", 
            "wordpress", "tumblr", "facebook", "instagram", "twitter", "tiktok", 
            "eporner", "porn", "adult", "brasilescola", "uol.com", "cimentart", 
            "publicdomain", "lalr.co", "metroandalas", "undertec", "computer-bild", 
            "expertonline", "alamy", "shutterstock", "gettyimages", "stock", 
            "wikipedia", "wikimedia", "wiki", "biobiochile", "blogs", "news", 
            "noticias", "articulo", "comparativa", "versus", "vs", "review",
            "imdb", "mv5b", "pxhere", "vecteezy", "silhouette", "avatar", "profile",
            "member", "avatar", "flag", "bandera", "escudo", "map", "mapa"
        ]
        if any(bad in url_lower for bad in blacklisted):
            score -= 50
            
        # 5. Extensiones preferidas
        if url_lower.endswith(".png") or "png" in url_lower:
            score += 2
            
        # 6. Evitar cruce de categorías (ej. reloj vs teléfono, auriculares vs teléfono)
        clash_groups = [
            # Relojes
            (["watch", "reloj", "band", "fit", "smartwatch"], 
             ["phone", "smartphone", "telefono", "movil", "cellphone", "tablet", "laptop", "tv"]),
            # Teléfonos
            (["phone", "smartphone", "telefono", "movil", "cellphone", "note"], 
             ["watch", "reloj", "band", "fit", "smartwatch", "buds", "earbuds", "headphone", "auriculares"])
        ]
        
        product_name_lower = product_name.lower()
        for keywords, clashes in clash_groups:
            # Si el nombre del producto contiene palabras clave de este grupo
            if any(kw in product_name_lower for kw in keywords):
                # Pero la URL contiene términos chocantes/excluyentes
                if any(clash in url_lower for clash in clashes):
                    score -= 35
                    
        # 7. Validar números de modelo (ej. si el nombre tiene "13" o "5", la URL debe coincidir con alguno)
        product_numbers = [w for w in product_words if w.isdigit()]
        if product_numbers:
            has_number_match = any(
                re.search(r'(?<!\d)' + re.escape(num) + r'(?!\d)', url_lower)
                for num in product_numbers
            )
            if not has_number_match:
                score -= 30
            
        return score

    @staticmethod
    def _search_brave_image(product_name: str) -> str | None:
        """Busca una imagen de producto en Brave Search usando curl.exe para evitar bloqueos TLS."""
        import subprocess
        import urllib.parse
        import re
        import html as html_lib
        
        # Limpiar consulta para Brave
        cleaned_query = ExtractorService._clean_product_name_for_search(product_name)
        if ExtractorService.is_device_or_appliance(product_name):
            cleaned_query = f"{cleaned_query} official product white background"
        logger.info(f"Buscando imagen en Brave Search para: {product_name} (Limpio: {cleaned_query})")
        encoded_query = urllib.parse.quote(cleaned_query)
        url = f"https://search.brave.com/images?q={encoded_query}"
        user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"
        
        try:
            cmd = ["curl", "-s", "-A", user_agent, url]
            # Ejecutar curl.exe de forma síncrona con un timeout
            result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", timeout=10)
            
            if result.returncode == 0 and result.stdout:
                html_text = html_lib.unescape(result.stdout)
                
                # Encontrar URLs de imágenes en Brave Search
                img_urls = re.findall(r'\"(https?://[^\"]+?\.(?:jpg|jpeg|png|webp))\"', html_text)
                filtered_urls = list(set([u for u in img_urls if "brave.com" not in u and "brave-static" not in u]))
                
                if not filtered_urls:
                    return None
                    
                scored_images = []
                for u in filtered_urls:
                    score = ExtractorService._score_image_url(u, product_name)
                    scored_images.append((score, u))
                    
                scored_images.sort(key=lambda x: x[0], reverse=True)
                best_score, best_img = scored_images[0]
                
                if best_score >= 15:
                    logger.info(f"Imagen seleccionada en Brave para '{product_name}' (Puntaje={best_score}): {best_img}")
                    return best_img
        except Exception as e:
            logger.warning(f"Error consultando Brave Search para '{product_name}': {e}")
        return None

    @staticmethod
    def _search_fragrantica_image(product_name: str) -> str | None:
        """Busca una imagen de perfume en Fragrantica (com/es) a través de Yandex Images con site-restriction y fallback."""
        import subprocess
        import urllib.parse
        import re
        import html as html_lib
        
        query = ExtractorService._clean_product_name_for_search(product_name)
        if len(query) < 3:
            return None
            
        # Variaciones de búsqueda en Yandex restringiendo por sitio para forzar imágenes de la base de datos de perfumes
        queries = [
            f"{query} site:fragrantica.com",
            f"{query} site:fragrantica.es",
            f"{query} fragrantica"
        ]
        
        user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"
        
        for idx, q_text in enumerate(queries):
            logger.info(f"Buscando perfume en Fragrantica (Yandex) para: {product_name} (Consulta {idx+1}: '{q_text}')")
            try:
                encoded_query = urllib.parse.quote(q_text)
                url = f"https://yandex.com/images/search?text={encoded_query}"
                cmd = ["curl", "-s", "-L", "-A", user_agent, url]
                result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", timeout=10)
                
                if result.returncode == 0 and result.stdout:
                    decoded_html = html_lib.unescape(result.stdout)
                    img_urls = re.findall(r'(https?://[^\s\"\'\<\>\\#]+?\.(?:jpg|jpeg|png|webp))', decoded_html)
                    
                    # Filtrar y priorizar URLs oficiales de Fragrantica (com, es y fimgs.net)
                    valid_urls = []
                    for u in img_urls:
                        u_lower = u.lower()
                        
                        # Exclusión estricta de notas/ingredientes (sastojci), avatares, noticias (vijesti/vijestiru/news), pirámides/cards y fotos amateur (photogram)
                        if any(bad in u_lower for bad in ["/sastojci/", "/avatari/", "/news/", "/vijesti", "/vijestiru/", "/perfume-social-cards/", "/photogram/", "/himg/"]):
                            continue
                            
                        if "fragrantica.com" in u_lower or "fragrantica.es" in u_lower or "fimgs.net" in u_lower:
                            # Priorizar frascos oficiales de la base de datos
                            priority = 0
                            if "/perfume-thumbs/" in u_lower:
                                priority = 100
                            elif "/perfume/" in u_lower:
                                priority = 90
                            elif "/secundar/" in u_lower:
                                priority = 70
                            else:
                                priority = 10
                            valid_urls.append((priority, u))
                    
                    if valid_urls:
                        # Ordenar por prioridad descendente
                        valid_urls.sort(key=lambda x: x[0], reverse=True)
                        best_img = valid_urls[0][1]
                        logger.info(f"Imagen de frasco Fragrantica seleccionada (Consulta {idx+1}, Prioridad={valid_urls[0][0]}): {best_img}")
                        return best_img
            except Exception as e:
                logger.warning(f"Error consultando Fragrantica en Yandex con consulta '{q_text}': {e}")
        return None

    @staticmethod
    def is_perfume(name: str) -> bool:
        import re
        name_lower = name.lower()
        perfume_indicators = [
            r'\b\d+\s*(?:ml|oz)\b',
            r'\bedp\b', r'\bedt\b',
            r'\beau\s+de\b',
            r'\bparfum\b', r'\btoilette\b',
            r'\bcologne\b', r'\bfragrance\b',
            r'\bperfume\b', r'\bseduction\b',
            r'\bblue\s+seduction\b', r'\bcolonia\b',
            r'\bfragrantica\b', r'\bsplash\b'
        ]
        return any(re.search(pat, name_lower) for pat in perfume_indicators)

    @staticmethod
    def is_device_or_appliance(name: str) -> bool:
        import re
        name_lower = name.lower()
        device_indicators = [
            r'\bgalaxy\b', r'\biphone\b', r'\bxiaomi\b', r'\bredmi\b',
            r'\bhuawei\b', r'\bmotorola\b', r'\bcelular\b', r'\btelefono\b',
            r'\bsmartphone\b', r'\bmoto\s+g\b', r'\blavadora\b', r'\bnevera\b',
            r'\brefrigerador\b', r'\bsecadora\b', r'\bestufa\b', r'\bmicroondas\b',
            r'\bhorno\b', r'\bdrija\b', r'\btope\b', r'\blicuadora\b', r'\bextractor\b',
            r'\baire\s+acondicionado\b', r'\bcocina\b', r'\btelevisor\b', r'\bsmart\s+tv\b',
            r'\bfreezer\b', r'\bcongelador\b'
        ]
        return any(re.search(pat, name_lower) for pat in device_indicators)

    @staticmethod
    def _search_yandex_image(product_name: str) -> str | None:
        """Busca una imagen de producto en Yandex Images usando curl con soporte de variaciones fallback."""
        import subprocess
        import urllib.parse
        import re
        import html as html_lib
        
        cleaned_query = ExtractorService._clean_product_name_for_search(product_name)
        queries = []
        if ExtractorService.is_device_or_appliance(product_name):
            # Usar comillas para buscar el nombre exacto del modelo y forzar fondo blanco
            queries.append((f'"{cleaned_query}" official product white background', 25))
            queries.append((f'"{cleaned_query}" producto fondo blanco', 25))
            queries.append((cleaned_query, 20))  # Fallback sin fondo blanco pero con nombre exacto
        else:
            queries.append((cleaned_query, 15))
        # Siempre incluir el nombre original como fallback de baja prioridad
        queries.append((product_name, 10))

        user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"
        
        for idx, (q_text, min_score) in enumerate(queries):
            logger.info(f"Buscando imagen en Yandex Images para: {product_name} (Consulta {idx+1}: {q_text})")
            try:
                encoded_query = urllib.parse.quote(q_text)
                url = f"https://yandex.com/images/search?text={encoded_query}"
                cmd = ["curl", "-s", "-L", "-A", user_agent, url]
                result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", timeout=10)
                
                if result.returncode == 0 and result.stdout:
                    decoded_html = html_lib.unescape(result.stdout)
                    img_urls = re.findall(r'(https?://[^\s\"\'\<\>\\#]+?\.(?:jpg|jpeg|png|webp))', decoded_html)
                    filtered_urls = list(set([u for u in img_urls if "yandex" not in u and "yastatic" not in u]))
                    
                    if not filtered_urls:
                        continue
                        
                    scored_images = []
                    for u in filtered_urls:
                        score = ExtractorService._score_image_url(u, product_name)
                        scored_images.append((score, u))
                        
                    scored_images.sort(key=lambda x: x[0], reverse=True)
                    best_score, best_img = scored_images[0]
                    
                    if best_score >= min_score:
                        logger.info(f"Imagen seleccionada en Yandex para '{product_name}' con consulta '{q_text}' (Puntaje={best_score}): {best_img}")
                        return best_img
            except Exception as e:
                logger.warning(f"Error consultando Yandex con '{q_text}': {e}")
                
        return None

    @staticmethod
    def search_image(product_name: str) -> str | None:
        """Busca una imagen del producto (primero Fragrantica, luego Yandex, luego Brave Search, luego Bing)."""
        if not product_name or not isinstance(product_name, str):
            return None
            
        name_clean = product_name.strip().lower()
        if len(name_clean) < 3:
            logger.warning(f"Nombre de producto demasiado corto para buscar imagen: '{product_name}'")
            return None
            
        # Ignorar términos genéricos y cabeceras comunes de planillas/facturas
        ignored_terms = {
            "nombre", "precio", "cantidad", "especificaciones", "total", "subtotal",
            "factura", "fecha", "código", "codigo", "item", "producto", "product",
            "price", "quantity", "specs", "stock", "iva", "descuento", "description",
            "descripción", "unidades", "unidad", "cant.", "detalles", "details",
            "monto", "valor", "costo", "cost", "total general", "gran total", "general"
        }
        if name_clean in ignored_terms:
            logger.warning(f"Evitando buscar imagen para término genérico/cabecera: '{product_name}'")
            return None
            
        logger.info(f"Iniciando búsqueda de imagen para: {product_name}")
        
        # 1. Si es perfume, buscar únicamente en Fragrantica
        if ExtractorService.is_perfume(product_name):
            logger.info(f"El producto '{product_name}' ha sido detectado como PERFUME. Búsqueda exclusiva en Fragrantica.")
            return ExtractorService._search_fragrantica_image(product_name)
            
        # 2. Si no es perfume, intentar primero con Yandex Images (excelente tasa de éxito sin bloqueos)
        yandex_img = ExtractorService._search_yandex_image(product_name)
        if yandex_img:
            return yandex_img
            
        # 3. Intentar con Brave Search general (usando curl)
        brave_img = ExtractorService._search_brave_image(product_name)
        if brave_img:
            return brave_img
            
        # 3. Fallback a Bing recorriendo variaciones usando curl y requiriendo score >= 15
        import subprocess
        import re
        import urllib.parse
        import html as html_lib
        
        logger.warning(f"Brave Search no devolvió imagen apta para '{product_name}'. Usando fallback de Bing...")
        
        cleaned = ExtractorService._clean_product_name_for_search(product_name)
        
        if ExtractorService.is_device_or_appliance(product_name):
            variations = [
                f"{cleaned} official product white background",
                f"{cleaned} producto fondo blanco",
                f"{cleaned} png"
            ]
        else:
            variations = [
                cleaned,
                f"{cleaned} png"
            ]
        
        user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"
        
        for var in variations:
            if not var or var.strip() == "":
                continue
            try:
                encoded_query = urllib.parse.quote(var)
                url = f"https://www.bing.com/images/search?q={encoded_query}"
                cmd = ["curl", "-s", "-L", "-A", user_agent, url]
                result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", timeout=10)
                
                if result.returncode == 0 and result.stdout:
                    decoded_html = html_lib.unescape(result.stdout)
                    matches = re.findall(r'"murl"\s*:\s*"([^"]+)"', decoded_html)
                    
                    if not matches:
                        continue
                        
                    scored_images = []
                    for m in matches:
                        score = ExtractorService._score_image_url(m, product_name)
                        scored_images.append((score, m))
                        
                    scored_images.sort(key=lambda x: x[0], reverse=True)
                    best_score, best_img = scored_images[0]
                    
                    if best_score >= 15:
                        logger.info(f"Imagen seleccionada en Bing con consulta '{var}' (Puntaje={best_score}): {best_img}")
                        return best_img
            except Exception as e:
                logger.warning(f"Búsqueda en Bing con '{var}' falló: {e}")
                
        return None

    @staticmethod
    def extract_images_from_xlsx(file_bytes: bytes) -> dict:
        """
        Parsea un archivo XLSX como ZIP y extrae imágenes incrustadas asociadas a sus filas.
        Devuelve un diccionario: {fila_index (0-based): (nombre_archivo, bytes_imagen)}
        """
        import zipfile
        import xml.etree.ElementTree as ET
        import re
        
        images_by_row = {}
        try:
            with zipfile.ZipFile(io.BytesIO(file_bytes)) as z:
                # 1. Encontrar relaciones de dibujo
                drawing_rels = {}
                for name in z.namelist():
                    if name.startswith("xl/drawings/_rels/") and name.endswith(".rels"):
                        try:
                            xml_content = z.read(name)
                            root = ET.fromstring(xml_content)
                            for child in root:
                                r_id = child.attrib.get("Id")
                                target = child.attrib.get("Target")
                                if r_id and target:
                                    clean_target = target.replace("../", "xl/")
                                    drawing_rels[r_id] = clean_target
                        except Exception as e:
                            logger.warning(f"Error parseando rels de dibujo {name}: {e}")

                # 2. Parsear los dibujos para saber en qué celda/fila está cada imagen
                for name in z.namelist():
                    if name.startswith("xl/drawings/") and name.endswith(".xml") and not "_rels" in name:
                        try:
                            xml_content = z.read(name)
                            # Remover namespaces para facilitar la búsqueda con ElementTree
                            xml_str = re.sub(r' xmlns="[^"]+"', '', xml_content.decode("utf-8", errors="ignore"))
                            xml_str = re.sub(r'xmlns:\w+="[^"]+"', '', xml_str)
                            xml_str = re.sub(r'<\w+:', '<', xml_str)
                            xml_str = re.sub(r'</\w+:', '</', xml_str)
                            
                            root = ET.fromstring(xml_str.encode("utf-8"))
                            anchors = root.findall(".//twoCellAnchor") + root.findall(".//oneCellAnchor")
                            
                            for anchor in anchors:
                                from_elem = anchor.find(".//from")
                                if from_elem is not None:
                                    row_elem = from_elem.find("row")
                                    if row_elem is not None:
                                        row_idx = int(row_elem.text)
                                        
                                        blip = anchor.find(".//blip")
                                        if blip is not None:
                                            r_id = None
                                            for attr, val in blip.attrib.items():
                                                if attr.endswith("embed"):
                                                    r_id = val
                                                    break
                                                    
                                            if r_id and r_id in drawing_rels:
                                                img_path = drawing_rels[r_id]
                                                try:
                                                    img_bytes = z.read(img_path)
                                                    filename = img_path.split("/")[-1]
                                                    images_by_row[row_idx] = (filename, img_bytes)
                                                except Exception as e:
                                                    logger.warning(f"Error al leer bytes de imagen {img_path}: {e}")
                        except Exception as e:
                            logger.warning(f"Error parseando archivo de dibujo {name}: {e}")
                            
        except Exception as e:
            logger.warning(f"Error al abrir XLSX como ZIP para extraer imágenes: {e}")
            
        return images_by_row

    @staticmethod
    def extract_from_excel(file_bytes: bytes) -> List[Dict[str, Any]]:
        """Procesa un archivo Excel y devuelve una lista de productos con sus imágenes asociadas."""
        try:
            wb = openpyxl.load_workbook(io.BytesIO(file_bytes), data_only=True)
            sheet = wb.active
            if not sheet:
                return []

            # Extraer imágenes incrustadas de forma nativa
            images_by_row = {}
            try:
                images_by_row = ExtractorService.extract_images_from_xlsx(file_bytes)
                logger.info(f"Imágenes extraídas de Excel: {len(images_by_row)}")
            except Exception as e:
                logger.warning(f"No se pudieron extraer imágenes del Excel: {e}")

            # Leer filas y determinar encabezados
            rows = list(sheet.iter_rows(values_only=True))
            if not rows:
                return []

            headers = [str(cell).strip() if cell is not None else "" for cell in rows[0]]
            
            # Buscar índices de columnas comunes
            name_idx = -1
            specs_idx = -1
            price_idx = -1
            qty_idx = -1

            name_hints = ["nombre", "name", "producto", "product", "artículo", "articulo", "item", "descripción corta"]
            specs_hints = ["especificaciones", "specs", "descripción", "descripcion", "details", "detalle", "características", "features"]
            price_hints = ["precio", "price", "costo", "cost", "valor", "monto"]
            qty_hints = ["cantidad", "qty", "stock", "cant", "quantity", "unidades", "existencia"]

            for idx, h in enumerate(headers):
                h_lower = h.lower()
                if any(hint in h_lower for hint in name_hints) and name_idx == -1:
                    name_idx = idx
                elif any(hint in h_lower for hint in specs_hints) and specs_idx == -1:
                    specs_idx = idx
                elif any(hint in h_lower for hint in price_hints) and price_idx == -1:
                    price_idx = idx
                elif any(hint in h_lower for hint in qty_hints) and qty_idx == -1:
                    qty_idx = idx

            # Si no encontramos por nombre de columna exacto, usar mapeo posicional por defecto
            if name_idx == -1 and len(headers) > 0: name_idx = 0
            if price_idx == -1 and len(headers) > 1: price_idx = 1
            if qty_idx == -1 and len(headers) > 2: qty_idx = 2
            if specs_idx == -1 and len(headers) > 3: specs_idx = 3

            extracted_products = []
            for idx, row in enumerate(rows[1:], start=1):
                # Asegurar que la fila tiene suficientes elementos
                if name_idx >= len(row) or row[name_idx] is None:
                    continue
                
                name = str(row[name_idx]).strip()
                if not name:
                    continue

                specs = ""
                if specs_idx != -1 and specs_idx < len(row) and row[specs_idx] is not None:
                    specs = str(row[specs_idx]).strip()

                price = 0.0
                if price_idx != -1 and price_idx < len(row) and row[price_idx] is not None:
                    try:
                        price = float(row[price_idx])
                    except (ValueError, TypeError):
                        pass

                qty = 0
                if qty_idx != -1 and qty_idx < len(row) and row[qty_idx] is not None:
                    try:
                        qty = int(row[qty_idx])
                    except (ValueError, TypeError):
                        pass

                # Mapear imagen asociada a la fila (openpyxl row start=1 coincide con la fila 0-based en drawings)
                image_filename = None
                image_bytes = None
                img_data = images_by_row.get(idx)
                if img_data:
                    image_filename, image_bytes = img_data
                    logger.info(f"Imagen asociada al producto de la fila {idx}: {image_filename}")

                extracted_products.append({
                    "name": name,
                    "specifications": specs,
                    "price": price,
                    "quantity": qty,
                    "image_filename": image_filename,
                    "image_bytes": image_bytes
                })

            return extracted_products
        except Exception as e:
            logger.error(f"Error procesando Excel: {e}")
            raise Exception(f"Error procesando Excel: {str(e)}")

    @staticmethod
    def extract_with_groq(file_bytes: bytes, mime_type: str) -> List[Dict[str, Any]]:
        """Extrae productos usando Groq Vision."""
        api_key = os.getenv("GROQ_API_KEY")
        if not api_key:
            raise ValueError("Falta GROQ_API_KEY en variables de entorno")

        client = Groq(api_key=api_key)
        base64_image = base64.b64encode(file_bytes).decode("utf-8")

        # Actualizado con los modelos de Groq activos
        models_to_try = [
            "meta-llama/llama-4-scout-17b-16e-instruct"
        ]

        last_error = None
        for model_id in models_to_try:
            try:
                logger.info(f"Intentando Groq Vision con modelo: {model_id}")
                response = client.chat.completions.create(
                    model=model_id,
                    messages=[
                        {
                            "role": "user",
                            "content": [
                                {
                                    "type": "text",
                                    "text": (
                                        "Extrae una lista de productos de esta imagen. Devuelve SOLO un JSON array "
                                        "con objetos que tengan exactamente las siguientes llaves: name, specifications, "
                                        "price (number), quantity (number). Ejemplo: [{\"name\": \"Producto\", "
                                        "\"specifications\": \"...\", \"price\": 100.0, \"quantity\": 5}]."
                                    )
                                },
                                {
                                    "type": "image_url",
                                    "image_url": {
                                        "url": f"data:{mime_type};base64,{base64_image}"
                                    }
                                }
                            ]
                        }
                    ],
                    response_format={"type": "json_object"}
                )

                content = response.choices[0].message.content
                if not content:
                    continue

                parsed = json.loads(content)
                
                # Lógica de parseo mejorada similar a la de extractor.ts
                if isinstance(parsed, list):
                    return parsed
                elif isinstance(parsed, dict):
                    # Buscar la primera lista dentro del objeto (caso {"products": [...]})
                    for val in parsed.values():
                        if isinstance(val, list):
                            return val
                    # Si no hay lista, retornar el objeto como único elemento si tiene los campos
                    if all(k in parsed for k in ["name", "price"]):
                        return [parsed]
                return []
            except Exception as e:
                logger.warning(f"Fallo Groq con {model_id}: {str(e)}")
                last_error = e
                continue

        raise last_error or Exception("Todos los modelos de Groq Vision fallaron")

    @staticmethod
    def extract_from_text(text: str) -> List[Dict[str, Any]]:
        """Extrae productos a partir de texto usando Groq."""
        api_key = os.getenv("GROQ_API_KEY")
        if not api_key:
            raise ValueError("Falta GROQ_API_KEY en variables de entorno")

        client = Groq(api_key=api_key)

        try:
            logger.info("Intentando Groq Text extraction")
            response = client.chat.completions.create(
                model="llama-3.3-70b-versatile",
                messages=[
                    {
                        "role": "system",
                        "content": (
                            "Eres un asistente experto en analizar texto de listados de productos (por ejemplo WhatsApp). "
                            "Extrae una lista de productos a partir del texto ingresado. "
                            "Devuelve SOLO un JSON con una llave 'products' que contenga un array "
                            "con objetos que tengan exactamente las siguientes llaves: "
                            "name (solo la marca y descripción general, SIN el modelo), "
                            "specifications (el modelo exacto o código alfanumérico del producto, ej: WT18WVTM), "
                            "price (number extraído del texto, sin símbolos), quantity (number, asume 1 si no dice), category (infiere una categoría general, ej: 'Línea Blanca', 'Telefonía', 'Perfumes'). "
                            "Ejemplo: {\"products\": [{\"name\": \"LAVADORA LG 18KG BLANCA\", \"specifications\": \"WT18WVTM\", "
                            "\"price\": 620.0, \"quantity\": 1, \"category\": \"Linea Blanca\"}]}"
                        )
                    },
                    {
                        "role": "user",
                        "content": text
                    }
                ],
                response_format={"type": "json_object"}
            )

            content = response.choices[0].message.content
            if not content:
                return []

            parsed = json.loads(content)
            for val in parsed.values():
                if isinstance(val, list):
                    return val
            if isinstance(parsed, list):
                return parsed
            if isinstance(parsed, dict) and all(k in parsed for k in ["name", "price"]):
                return [parsed]
            return []
        except Exception as e:
            logger.error(f"Fallo Groq text extraction: {str(e)}")
            raise Exception(f"Fallo Groq text extraction: {str(e)}")
