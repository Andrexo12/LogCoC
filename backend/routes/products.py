from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database.db import get_db
from services.product_service import ProductService
from models.product import ProductSchema

router = APIRouter(prefix="/products", tags=["Products"])

@router.get("/{qr_id}", response_model=ProductSchema)
def get_product(qr_id: str, db: Session = Depends(get_db)):
    product = ProductService.get_product_by_qr(db, qr_id)
    if not product:
        raise HTTPException(status_code=404, detail="Producto no encontrado en Innova Center")
    return product
