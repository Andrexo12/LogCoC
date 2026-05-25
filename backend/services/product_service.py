import math
from sqlalchemy.orm import Session
from models.product import Product

class ProductService:
    @staticmethod
    def apply_rounding(price: float) -> float:
        """Aplica la regla de redondeo al 0.50 superior."""
        return math.ceil(price * 2) / 2

    @staticmethod
    def get_product_by_qr(db: Session, qr_id: str):
        return db.query(Product).filter(Product.qr_id == qr_id).first()

    @staticmethod
    def get_all_products(db: Session, type: str = None, category: str = None, search: str = None):
        query = db.query(Product)
        if type:
            query = query.filter(Product.product_type == type)
        if category:
            query = query.filter(Product.category == category)
        if search:
            query = query.filter(Product.name.contains(search))
        return query.all()

    @staticmethod
    def create_product(db: Session, product_data: dict):
        new_product = Product(**product_data)
        db.add(new_product)
        db.commit()
        db.refresh(new_product)
        return new_product

    @staticmethod
    def update_product(db: Session, product_id: int, product_data: dict):
        product = db.query(Product).filter(Product.id == product_id).first()
        if product:
            for key, value in product_data.items():
                setattr(product, key, value)
            db.commit()
            db.refresh(product)
        return product

    @staticmethod
    def delete_product(db: Session, product_id: int):
        product = db.query(Product).filter(Product.id == product_id).first()
        if product:
            db.delete(product)
            db.commit()
            return True
        return False
