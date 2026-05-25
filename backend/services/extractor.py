import io
import os
import json
import base64
import logging
from typing import List, Dict, Any
import openpyxl
from groq import Groq
import google.generativeai as genai

logger = logging.getLogger(__name__)

class ExtractorService:
    @staticmethod
    def search_image(product_name: str) -> str | None:
        """Busca una imagen del producto en la web usando DuckDuckGo."""
        try:
            from duckduckgo_search import DDGS
            logger.info(f"Buscando imagen para: {product_name}")
            with DDGS() as ddgs:
                results = list(ddgs.images(
                    keywords=f"{product_name} producto fondo blanco",
                    region="wt-wt",
                    safesearch="on",
                    size="Medium",
                    type_image="photo"
                ))
                if results:
                    # Retornar la primera imagen encontrada
                    return results[0].get("image")
        except Exception as e:
            logger.error(f"Error buscando imagen para {product_name}: {e}")
        return None

    @staticmethod
    def extract_from_excel(file_bytes: bytes) -> List[Dict[str, Any]]:
        """Procesa un archivo Excel y devuelve una lista de productos."""
        try:
            wb = openpyxl.load_workbook(io.BytesIO(file_bytes), data_only=True)
            sheet = wb.active
            if not sheet:
                return []

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
            for row in rows[1:]:
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

                extracted_products.append({
                    "name": name,
                    "specifications": specs,
                    "price": price,
                    "quantity": qty
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

        # Actualizado con los modelos del proyecto de importación
        models_to_try = [
            "meta-llama/llama-4-scout-17b-16e-instruct",
            "llama-3.2-11b-vision-preview",
            "llama-3.2-90b-vision-preview"
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
    def extract_with_gemini(file_bytes: bytes, mime_type: str) -> List[Dict[str, Any]]:
        """Extrae productos usando Google Gemini."""
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            raise ValueError("Falta GEMINI_API_KEY en variables de entorno")

        genai.configure(api_key=api_key)
        
        models_to_try = ["gemini-2.0-flash", "gemini-1.5-flash"]
        last_error = None

        prompt = (
            "Analiza el documento o imagen y extrae la lista de productos. Devuelve únicamente "
            "un JSON array con objetos que tengan exactamente los campos: name, specifications, price, quantity. "
            "No incluyas explicaciones ni bloques Markdown, solo el texto JSON puro."
        )

        for model_name in models_to_try:
            try:
                logger.info(f"Intentando Gemini con modelo: {model_name}")
                model = genai.GenerativeModel(model_name)
                
                response = model.generate_content([
                    prompt,
                    {
                        "mime_type": mime_type,
                        "data": file_bytes
                    }
                ])

                text = response.text.strip()
                
                # Quitar envoltorios markdown json si los tiene
                if text.startswith("```json"):
                    text = text[7:]
                if text.endswith("```"):
                    text = text[:-3]
                text = text.strip()

                parsed = json.loads(text)
                if isinstance(parsed, list):
                    return parsed
                elif isinstance(parsed, dict):
                    for val in parsed.values():
                        if isinstance(val, list):
                            return val
                    return []
                return []
            except Exception as e:
                logger.warning(f"Fallo Gemini con {model_name}: {str(e)}")
                last_error = e
                continue

        raise last_error or Exception("Gemini falló en todos los intentos")
