import uuid
import logging
import time
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, BackgroundTasks
from sqlalchemy.orm import Session
from database.db import get_db, SessionLocal
from models.product import Product
from services.extractor import ExtractorService
from routes.auth import require_role

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/products/import", tags=["Products Import"])

from utils.file_utils import save_local_image

def update_product_images_background(product_ids: list[int]):
    """Busca imágenes en segundo plano para no bloquear el request de importación."""
    db = SessionLocal()
    try:
        logger.info(f"Iniciando búsqueda de imágenes en segundo plano para {len(product_ids)} productos")
        for idx, p_id in enumerate(product_ids):
            # Añadir un delay entre búsquedas (excepto para la primera) para evitar rate-limits
            if idx > 0:
                time.sleep(3.5)
                
            product = db.query(Product).filter(Product.id == p_id).first()
            if product and not product.image_url:
                logger.info(f"Buscando imagen para: {product.name}")
                img_url = ExtractorService.search_image(product.name)
                if img_url:
                    product.image_url = img_url
                    db.commit()
                    logger.info(f"Imagen actualizada para producto {product.name}: {img_url}")
                else:
                    logger.warning(f"No se encontró imagen para producto: {product.name}")
    except Exception as e:
        logger.error(f"Error actualizando imágenes en segundo plano: {e}")
    finally:
        db.close()

@router.post("")
async def import_products(
    file: UploadFile = File(...),
    search_images: bool = True,
    contains_prices: bool = False,
    price_currency: str = "Divisas",
    apply_discount: bool = False,
    background_tasks: BackgroundTasks = None,
    db: Session = Depends(get_db),
    current_user = Depends(require_role("admin"))
):
    """
    Sube una factura (PDF/Imagen) o una planilla Excel, extrae la lista
    de productos usando IA (Groq) o procesamiento Excel, y los inserta en el catálogo.
    Maneja la búsqueda de imágenes opcionalmente en segundo plano.
    """
    filename = file.filename or "archivo_subido"
    extension = filename.split(".")[-1].lower() if "." in filename else ""
    content_type = file.content_type or ""
    
    logger.info(f"Iniciando importación: archivo={filename}, extensión={extension}, content_type={content_type}, search_images={search_images}")

    try:
        file_bytes = await file.read()
    except Exception as e:
        logger.error(f"Error al leer el archivo subido: {e}")
        raise HTTPException(status_code=400, detail="No se pudo leer el archivo subido")

    extracted_products = []
    is_image = extension in ["jpg", "jpeg", "png", "webp"] or content_type.startswith("image/")
    is_pdf = extension == "pdf" or content_type == "application/pdf"
    is_excel = extension in ["xlsx", "xls"] or "spreadsheetml" in content_type or "ms-excel" in content_type

    uploaded_image_url = None
    if is_image:
        try:
            uploaded_image_url = save_local_image(file_bytes, filename)
            logger.info(f"Imagen subida guardada localmente: {uploaded_image_url}")
        except Exception as e:
            logger.error(f"Error al guardar imagen de producto subida: {e}")

    try:
        from utils.validation import is_valid_key

        if is_excel:
            logger.info("Procesando archivo como planilla Excel.")
            extracted_products = ExtractorService.extract_from_excel(file_bytes)
        elif is_pdf or is_image:
            logger.info(f"Procesando factura o imagen. Tipo: {content_type}, Extensión: {extension}")
            
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

            import os
            from dotenv import load_dotenv
            load_dotenv(override=True)
            groq_key = os.getenv("GROQ_API_KEY")

            if is_valid_key(groq_key):
                extracted_products = ExtractorService.extract_with_groq(file_bytes, mime_type)
            else:
                raise HTTPException(status_code=500, detail="Error de configuración: No se encontró la API Key de Groq.")
        else:
            raise HTTPException(status_code=400, detail=f"Formato de archivo no soportado: .{extension}")
    except Exception as e:
        logger.error(f"Error durante la extracción: {e}")
        raise HTTPException(status_code=422, detail=f"Error al extraer productos: {str(e)}")

    if not extracted_products:
        raise HTTPException(status_code=422, detail="No se pudieron extraer productos válidos")

    products_added = []
    try:
        rate = 1.85
        
        for p in extracted_products:
            unique_qr = f"prod-{uuid.uuid4().hex[:6]}"
            
            # 1. Si el producto tiene una imagen incrustada (en bytes) del Excel
            img_url = None
            if p.get("image_bytes") and p.get("image_filename"):
                try:
                    img_url = save_local_image(p["image_bytes"], p["image_filename"])
                    logger.info(f"Imagen incrustada de Excel guardada: {img_url}")
                except Exception as e:
                    logger.error(f"Error al guardar imagen incrustada de Excel: {e}")
            
            # 2. Si no tiene imagen del Excel pero el archivo subido en sí era una foto del producto (y solo se detectó 1 producto)
            if not img_url and uploaded_image_url and len(extracted_products) == 1:
                img_url = uploaded_image_url

            raw_price = float(p.get("price") or 0.0)
            
            name_lower = (p.get("name") or "").lower()
            cat_lower = (p.get("category") or "").lower()
            is_perfume = "perfume" in name_lower or "fragancia" in name_lower or "perfume" in cat_lower
            
            db_price = raw_price
            if is_perfume:
                if price_currency == "Divisas":
                    db_price = raw_price * 2
                else:
                    db_price = raw_price
            else:
                if price_currency == "Bolívares":
                    if apply_discount:
                        db_price = raw_price / (rate * 0.9)
                    else:
                        db_price = raw_price / rate
                else:
                    db_price = raw_price

            final_price = db_price

            product_name = p.get("name") or "Producto sin nombre"
            is_perfume = "perfume" in product_name.lower() or "fragancia" in product_name.lower()
            
            new_prod = Product(
                qr_id=unique_qr,
                name=product_name,
                description=p.get("specifications") or "",
                price=final_price,
                stock=int(p.get("quantity") or 0),
                category="Perfumería" if is_perfume else "General",
                product_type="Electrodomésticos",
                image_url=img_url,
                is_ar_visible=1
            )
            db.add(new_prod)
            products_added.append(new_prod)
        
        db.commit()
        for p in products_added:
            db.refresh(p)
            
        if search_images:
            ids_to_search = [p.id for p in products_added if not p.image_url]
            if ids_to_search:
                # Si son 8 o menos, buscamos todos de forma síncrona para que aparezcan de inmediato
                if len(ids_to_search) <= 8:
                    logger.info(f"Buscando imágenes de forma síncrona para {len(ids_to_search)} productos (importación corta)...")
                    for p in products_added:
                        if not p.image_url:
                            img_url = ExtractorService.search_image(p.name)
                            if img_url:
                                p.image_url = img_url
                    db.commit()
                else:
                    # Si son más de 8, buscamos los primeros 3 síncronos y el resto en segundo plano
                    logger.info(f"Buscando imágenes mixtas: 3 síncronas y el resto en segundo plano...")
                    sync_ids = ids_to_search[:3]
                    async_ids = ids_to_search[3:]
                    
                    for p in products_added:
                        if p.id in sync_ids and not p.image_url:
                            img_url = ExtractorService.search_image(p.name)
                            if img_url:
                                p.image_url = img_url
                    db.commit()
                    
                    if background_tasks and async_ids:
                        background_tasks.add_task(update_product_images_background, async_ids)
                
                # Refrescar los productos modificados
                for p in products_added:
                    db.refresh(p)
                
    except Exception as e:
        db.rollback()
        logger.error(f"Error al guardar los productos en la BD: {e}")
        raise HTTPException(status_code=500, detail=f"Error de base de datos: {str(e)}")

    return {
        "success": True,
        "message": f"Se agregaron {len(products_added)} productos.",
        "data": {
            "imported_count": len(products_added),
            "products": [
                {
                    "id": p.id,
                    "qr_id": p.qr_id,
                    "name": p.name,
                    "price": p.price,
                    "stock": p.stock
                }
                for p in products_added
            ]
        }
    }

from pydantic import BaseModel
class ImportTextRequest(BaseModel):
    text: str
    search_images: bool = False
    contains_prices: bool = False
    price_currency: str = "Divisas"
    apply_discount: bool = False

@router.post("/text")
def import_products_text(
    request: ImportTextRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    try:
        extracted_products = ExtractorService.extract_from_text(request.text)
    except Exception as e:
        logger.error(f"Error extrayendo de texto: {e}")
        raise HTTPException(status_code=422, detail=f"Error al extraer productos del texto: {e}")
        
    if not extracted_products:
        raise HTTPException(status_code=422, detail="No se pudieron extraer productos del texto")
        
    products_added = []
    try:
        rate = 1.85
        for p in extracted_products:
            unique_qr = f"prod-{uuid.uuid4().hex[:6]}"
            raw_price = float(p.get("price") or 0.0)
            
            name_lower = (p.get("name") or "").lower()
            cat_lower = (p.get("category") or "").lower()
            is_perfume = "perfume" in name_lower or "fragancia" in name_lower or "perfume" in cat_lower
            
            db_price = raw_price
            if is_perfume:
                if request.price_currency == "Divisas":
                    db_price = raw_price * 2
                else:
                    db_price = raw_price
            else:
                if request.price_currency == "Bolívares":
                    if request.apply_discount:
                        db_price = raw_price / (rate * 0.9)
                    else:
                        db_price = raw_price / rate
                else:
                    db_price = raw_price

            final_price = db_price

            new_prod = Product(
                qr_id=unique_qr,
                name=p.get("name") or "Producto sin nombre",
                description=p.get("specifications") or "",
                price=final_price,
                stock=int(p.get("quantity") or 1),
                category=p.get("category") or "General",
                product_type="Linea Blanca",
                image_url=None,
                is_ar_visible=1
            )
            db.add(new_prod)
            products_added.append(new_prod)
        db.commit()
        for p in products_added:
            db.refresh(p)
            
        if request.search_images:
            ids_to_search = [p.id for p in products_added]
            if len(ids_to_search) <= 8:
                for p in products_added:
                    img_url = ExtractorService.search_image(p.name)
                    if img_url:
                        p.image_url = img_url
                db.commit()
            else:
                sync_ids = ids_to_search[:3]
                async_ids = ids_to_search[3:]
                for p in products_added:
                    if p.id in sync_ids:
                        img_url = ExtractorService.search_image(p.name)
                        if img_url:
                            p.image_url = img_url
                db.commit()
                if background_tasks and async_ids:
                    background_tasks.add_task(update_product_images_background, async_ids)
            for p in products_added:
                db.refresh(p)
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))
        
    return {
        "success": True,
        "message": f"Se agregaron {len(products_added)} productos desde texto.",
        "data": {
            "imported_count": len(products_added),
            "products": [{"id": p.id, "name": p.name} for p in products_added]
        }
    }
