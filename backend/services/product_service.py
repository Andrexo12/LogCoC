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
        from models.lookup import Categoria, TipoProducto
        query = db.query(Product).join(Categoria, Product.category_id == Categoria.id, isouter=True)\
                                 .join(TipoProducto, Product.product_type_id == TipoProducto.id, isouter=True)
        if type:
            query = query.filter(TipoProducto.nombre == type)
        if category:
            query = query.filter(Categoria.nombre == category)
        if search:
            query = query.filter(Product.name.contains(search))
        return query.all()

    @staticmethod
    def _handle_lookups(db: Session, product_data: dict):
        from models.lookup import Categoria, TipoProducto
        if "category" in product_data:
            cat_name = product_data.pop("category")
            if cat_name:
                cat = db.query(Categoria).filter_by(nombre=cat_name).first()
                if not cat:
                    cat = Categoria(nombre=cat_name)
                    db.add(cat)
                    db.commit()
                    db.refresh(cat)
                product_data["category_id"] = cat.id
            else:
                product_data["category_id"] = None
                
        if "product_type" in product_data:
            type_name = product_data.pop("product_type")
            if type_name:
                ptype = db.query(TipoProducto).filter_by(nombre=type_name).first()
                if not ptype:
                    ptype = TipoProducto(nombre=type_name)
                    db.add(ptype)
                    db.commit()
                    db.refresh(ptype)
                product_data["product_type_id"] = ptype.id
            else:
                product_data["product_type_id"] = None
                
        return product_data

    @staticmethod
    def create_product(db: Session, product_data: dict):
        product_data = ProductService._handle_lookups(db, product_data)
        new_product = Product(**product_data)
        db.add(new_product)
        db.commit()
        db.refresh(new_product)
        return new_product

    @staticmethod
    def update_product(db: Session, product_id: int, product_data: dict):
        product_data = ProductService._handle_lookups(db, product_data)
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
