from fastapi import APIRouter, Depends, HTTPException, Request, Response, BackgroundTasks, UploadFile, File
from sqlalchemy.orm import Session
from database.db import get_db
from services.product_service import ProductService
from models.product import ProductSchema
from typing import List, Optional
import logging
from routes.auth import require_role

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/products", tags=["Products"])

def rewrite_image_url(p_dict: dict, request: Request) -> dict:
    if not p_dict.get("image_url"):
        return p_dict
        
    # Si la imagen es local (/static/...)
    if p_dict["image_url"].startswith("/static/"):
        headers = request.headers
        proto = headers.get("x-forwarded-proto", request.url.scheme)
        host = headers.get("x-forwarded-host", request.url.netloc)
        base_url = f"{proto}://{host}"
        base_clean = base_url if base_url.endswith("/") else f"{base_url}/"
        p_dict["image_url"] = f"{base_clean}{p_dict['image_url'].lstrip('/')}"
        return p_dict

    if p_dict["image_url"].startswith("http"):
        if "api/products/image-proxy" in p_dict["image_url"]:
            return p_dict
        
        # Soportar cabeceras de proxy de Codespaces / Nginx
        headers = request.headers
        proto = headers.get("x-forwarded-proto", request.url.scheme)
        host = headers.get("x-forwarded-host", request.url.netloc)
        base_url = f"{proto}://{host}"
        
        import urllib.parse
        encoded_url = urllib.parse.quote(p_dict["image_url"])
        base_clean = base_url if base_url.endswith("/") else f"{base_url}/"
        p_dict["image_url"] = f"{base_clean}api/products/image-proxy?url={encoded_url}"
    return p_dict

def product_to_dict(p) -> dict:
    return {
        "id": p.id,
        "qr_id": p.qr_id,
        "name": p.name,
        "description": p.description,
        "price": p.price,
        "rounded_price": p.rounded_price,
        "stock": p.stock,
        "category": p.category,
        "product_type": p.product_type,
        "image_url": p.image_url,
        "is_ar_visible": p.is_ar_visible
    }

@router.get("/image-proxy")
def image_proxy(url: str):
    """Proxy para saltar restricciones de CORS y bloqueo de hotlinking. Redirige al origen en caso de fallo."""
    import requests
    from fastapi.responses import RedirectResponse
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36",
        "Referer": "https://www.google.com/"
    }
    try:
        r = requests.get(url, headers=headers, timeout=5)
        if r.status_code == 200:
            content_type = r.headers.get("Content-Type", "image/jpeg")
            return Response(content=r.content, media_type=content_type)
    except Exception as e:
        logger.warning(f"Error en proxy de imagen para {url}: {e}")
    
    # Fallback: Redirigir directamente a la URL original
    return RedirectResponse(url=url)

@router.get("/", response_model=List[ProductSchema])
def get_products(
    request: Request,
    type: Optional[str] = None, 
    category: Optional[str] = None, 
    search: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Obtiene el catálogo de productos con filtros de tipo, categoría y búsqueda por nombre."""
    products = ProductService.get_all_products(db, type, category, search)
    return [rewrite_image_url(product_to_dict(p), request) for p in products]

@router.post("/upload-image")
async def upload_product_image(
    request: Request,
    file: UploadFile = File(...),
    current_user = Depends(require_role("admin"))
):
    """Sube una imagen para un producto y devuelve su URL absoluta en el servidor."""
    filename = file.filename or "imagen.png"
    extension = filename.split(".")[-1].lower() if "." in filename else "png"
    if extension not in ["jpg", "jpeg", "png", "webp", "gif"]:
         raise HTTPException(status_code=400, detail="Formato de imagen no soportado")
         
    try:
        content = await file.read()
        from routes.import_products import save_local_image
        local_path = save_local_image(content, filename)
        
        # Convertir a URL absoluta
        headers = request.headers
        proto = headers.get("x-forwarded-proto", request.url.scheme)
        host = headers.get("x-forwarded-host", request.url.netloc)
        base_url = f"{proto}://{host}"
        base_clean = base_url if base_url.endswith("/") else f"{base_url}/"
        absolute_url = f"{base_clean}{local_path.lstrip('/')}"
        
        return {"image_url": absolute_url}
    except Exception as e:
        logger.error(f"Error al subir imagen de producto: {e}")
        raise HTTPException(status_code=500, detail=f"Error al guardar la imagen: {e}")

@router.delete("/bulk-delete")
def bulk_delete_products(
    payload: dict,
    db: Session = Depends(get_db),
    current_user = Depends(require_role("admin"))
):
    """Elimina múltiples productos a la vez a partir de sus IDs."""
    ids = payload.get("ids", [])
    if not ids:
        raise HTTPException(status_code=400, detail="Falta lista de IDs")
        
    try:
        from models.product import Product
        # Eliminar productos que coincidan con los IDs
        db.query(Product).filter(Product.id.in_(ids)).delete(synchronize_session=False)
        db.commit()
        return {"message": f"{len(ids)} productos eliminados con éxito"}
    except Exception as e:
        db.rollback()
        logger.error(f"Error al eliminar productos en masa: {e}")
        raise HTTPException(status_code=500, detail=f"Error en base de datos: {e}")

@router.get("/{qr_id}", response_model=ProductSchema)
def get_product(qr_id: str, request: Request, db: Session = Depends(get_db)):
    product = ProductService.get_product_by_qr(db, qr_id)
    if not product:
        raise HTTPException(status_code=404, detail="Producto no encontrado")
    return rewrite_image_url(product_to_dict(product), request)

# Endpoints de Administración
@router.post("/", response_model=ProductSchema)
def create_product(
    product_data: dict, 
    request: Request, 
    background_tasks: BackgroundTasks = None,
    db: Session = Depends(get_db),
    current_user = Depends(require_role("admin"))
):
    base_url = str(request.base_url)
    product = ProductService.create_product(db, product_data)
    
    # Buscar imagen en segundo plano si no se suministró una
    if product and (not product.image_url or product.image_url.strip() == ""):
        if background_tasks:
            from routes.import_products import update_product_images_background
            background_tasks.add_task(update_product_images_background, [product.id])
            
    return rewrite_image_url(product_to_dict(product), request)

@router.put("/{product_id}", response_model=ProductSchema)
def update_product(
    product_id: int, 
    product_data: dict, 
    request: Request, 
    background_tasks: BackgroundTasks = None,
    db: Session = Depends(get_db),
    current_user = Depends(require_role("admin"))
):
    base_url = str(request.base_url)
    product = ProductService.update_product(db, product_id, product_data)
    
    # Buscar imagen en segundo plano si quedó vacía tras la actualización
    if product and (not product.image_url or product.image_url.strip() == ""):
        if background_tasks:
            from routes.import_products import update_product_images_background
            background_tasks.add_task(update_product_images_background, [product.id])
            
    return rewrite_image_url(product_to_dict(product), request)

@router.delete("/{product_id}")
def delete_product(product_id: int, db: Session = Depends(get_db), current_user = Depends(require_role("admin"))):
    success = ProductService.delete_product(db, product_id)
    if not success:
        raise HTTPException(status_code=404, detail="Producto no encontrado")
    return {"message": "Producto eliminado con éxito"}

