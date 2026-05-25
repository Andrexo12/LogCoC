import uuid
import logging
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from database.db import get_db
from models.product import Product
from services.extractor import ExtractorService

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/products/import", tags=["Products Import"])

@router.post("")
async def import_products(
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    """
    Sube una factura (PDF/Imagen) o una planilla Excel, extrae la lista
    de productos usando IA (Groq/Gemini) o procesamiento Excel, y los inserta en el catálogo.
    """
    filename = file.filename or "archivo_subido"
    extension = filename.split(".")[-1].lower() if "." in filename else ""
    content_type = file.content_type or ""
    
    logger.info(f"Iniciando importación: archivo={filename}, extensión={extension}, content_type={content_type}")

    try:
        file_bytes = await file.read()
    except Exception as e:
        logger.error(f"Error al leer el archivo subido: {e}")
        raise HTTPException(status_code=400, detail="No se pudo leer el archivo subido")

    extracted_products = []

    try:
        def is_valid_key(key: str | None) -> bool:
            if not key:
                return False
            placeholder_terms = ["tu_groq_key", "tu_google_ai_key", "aqui", "placeholder", "your_api_key"]
            key_lower = key.strip().lower()
            return not any(term in key_lower for term in placeholder_terms)

        # Normalización de tipo para imágenes
        is_image = extension in ["jpg", "jpeg", "png", "webp"] or content_type.startswith("image/")
        is_pdf = extension == "pdf" or content_type == "application/pdf"
        is_excel = extension in ["xlsx", "xls"] or "spreadsheetml" in content_type or "ms-excel" in content_type

        if is_excel:
            logger.info("Procesando archivo como planilla Excel.")
            extracted_products = ExtractorService.extract_from_excel(file_bytes)
        elif is_pdf or is_image:
            logger.info(f"Procesando factura o imagen. Tipo: {content_type}, Extensión: {extension}")
            
            # Determinar mime_type de forma robusta
            if is_pdf:
                mime_type = "application/pdf"
            elif extension in ["jpg", "jpeg"] or "jpeg" in content_type or "jpg" in content_type:
                mime_type = "image/jpeg"
            elif extension == "png" or "png" in content_type:
                mime_type = "image/png"
            elif extension == "webp" or "webp" in content_type:
                mime_type = "image/webp"
            else:
                mime_type = content_type if (content_type and "/" in content_type) else "image/jpeg"

            logger.info(f"Mime type detectado para IA: {mime_type}")
            
            import os
            from dotenv import load_dotenv
            load_dotenv(override=True) # Forzar recarga de variables de entorno

            groq_key = os.getenv("GROQ_API_KEY")
            gemini_key = os.getenv("GEMINI_API_KEY")

            if is_valid_key(groq_key) and mime_type.startswith("image/"):
                extracted_products = ExtractorService.extract_with_groq(file_bytes, mime_type)
            elif is_valid_key(gemini_key):
                extracted_products = ExtractorService.extract_with_gemini(file_bytes, mime_type)
            else:
                logger.error("No hay claves de visión válidas configuradas en el archivo .env")
                raise HTTPException(
                    status_code=500, 
                    detail="Error de configuración: No se encontraron API Keys válidas (Groq/Gemini) para procesar imágenes."
                )
        else:
            raise HTTPException(
                status_code=400,
                detail=f"Formato de archivo no soportado: .{extension} / {content_type}"
            )
    except Exception as e:
        logger.error(f"Error durante la extracción del catálogo: {e}")
        raise HTTPException(status_code=422, detail=f"Error al extraer productos: {str(e)}")

    if not extracted_products:
        raise HTTPException(status_code=422, detail="No se pudieron extraer productos válidos del archivo")

    products_added = []
    try:
        for p in extracted_products:
            # Generar qr_id único
            unique_qr = f"prod-{uuid.uuid4().hex[:6]}"
            
            # Buscar imagen si no viene en la extracción
            img_url = p.get("image_url")
            if not img_url:
                img_url = ExtractorService.search_image(p.get("name") or "")

            # Crear modelo ORM
            new_prod = Product(
                qr_id=unique_qr,
                name=p.get("name") or "Producto sin nombre",
                description=p.get("specifications") or "",
                price=float(p.get("price") or 0.0),
                stock=int(p.get("quantity") or 0),
                category="General",
                product_type="Electrodomésticos",
                image_url=img_url,
                is_ar_visible=1
            )
            db.add(new_prod)
            products_added.append(new_prod)
        
        db.commit()
        for p in products_added:
            db.refresh(p)
    except Exception as e:
        db.rollback()
        logger.error(f"Error al guardar los productos en la BD: {e}")
        raise HTTPException(status_code=500, detail=f"Error de base de datos al registrar productos: {str(e)}")

    return {
        "message": "Importación completada exitosamente",
        "imported_count": len(products_added),
        "products": [
            {
                "id": p.id,
                "qr_id": p.qr_id,
                "name": p.name,
                "price": p.price,
                "rounded_price": p.rounded_price,
                "stock": p.stock
            }
            for p in products_added
        ]
    }
