import math
from sqlalchemy.orm import Session
from models.product import Product

class ProductService:
    @staticmethod
    def get_product_by_qr(db: Session, qr_id: str):
        product = db.query(Product).filter(Product.qr_id == qr_id).first()
        if product:
            # Regla de redondeo automático: redondear al múltiplo de 0.50 más cercano (Innova Center style)
            product.rounded_price = ProductService.apply_rounding(product.price)
        return product

    @staticmethod
    def apply_rounding(price: float) -> float:
        """
        Aplica redondeo al 0.50 superior para facilitar transacciones en Innova Center.
        Ejemplo: 10.15 -> 10.50, 10.60 -> 11.00
        """
        return math.ceil(price * 2) / 2
