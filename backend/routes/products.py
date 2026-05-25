from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database.db import get_db
from services.product_service import ProductService
from models.product import ProductSchema
from typing import List, Optional

router = APIRouter(prefix="/products", tags=["Products"])

@router.get("/", response_model=List[ProductSchema])
def get_products(
    type: Optional[str] = None, 
    category: Optional[str] = None, 
    search: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Obtiene el catálogo de productos con filtros de tipo, categoría y búsqueda por nombre."""
    return ProductService.get_all_products(db, type, category, search)

@router.get("/{qr_id}", response_model=ProductSchema)
def get_product(qr_id: str, db: Session = Depends(get_db)):
    product = ProductService.get_product_by_qr(db, qr_id)
    if not product:
        raise HTTPException(status_code=404, detail="Producto no encontrado")
    return product

# Endpoints de Administración
@router.post("/", response_model=ProductSchema)
def create_product(product_data: dict, db: Session = Depends(get_db)):
    # TODO: Agregar verificación de rol admin aquí
    return ProductService.create_product(db, product_data)

@router.put("/{product_id}", response_model=ProductSchema)
def update_product(product_id: int, product_data: dict, db: Session = Depends(get_db)):
    # TODO: Agregar verificación de rol admin aquí
    return ProductService.update_product(db, product_id, product_data)

@router.delete("/{product_id}")
def delete_product(product_id: int, db: Session = Depends(get_db)):
    success = ProductService.delete_product(db, product_id)
    if not success:
        raise HTTPException(status_code=404, detail="Producto no encontrado")
    return {"message": "Producto eliminado con éxito"}
