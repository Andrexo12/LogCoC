from sqlalchemy import Column, Integer, String, Float, Text, ForeignKey
from sqlalchemy.orm import relationship
from database.db import Base
from pydantic import BaseModel
from models.lookup import Categoria, TipoProducto

class Product(Base):
    __tablename__ = "productos"

    id = Column("id", Integer, primary_key=True, index=True)
    qr_id = Column("id_qr", String(100), unique=True, index=True, nullable=False)
    name = Column("nombre", String(200), nullable=False)
    description = Column("descripcion", Text, nullable=True)
    price = Column("precio", Float, nullable=False)
    stock = Column("stock", Integer, default=0)
    category_id = Column("id_categoria", Integer, ForeignKey("categorias.id"), nullable=True)
    product_type_id = Column("id_tipo_producto", Integer, ForeignKey("tipos_producto.id"), nullable=True)
    model = Column("modelo", String(100), nullable=True)
    image_url = Column("url_imagen", Text, nullable=True)
    is_ar_visible = Column("es_visible_ra", Integer, default=1)

    category_rel = relationship("Categoria")
    product_type_rel = relationship("TipoProducto")

    @property
    def category(self) -> str:
        return self.category_rel.nombre if self.category_rel else None

    @property
    def product_type(self) -> str:
        return self.product_type_rel.nombre if self.product_type_rel else None

    @property
    def rounded_price(self) -> float:
        import math
        return math.ceil(self.price * 2) / 2

class ProductSchema(BaseModel):
    id: int
    qr_id: str
    name: str
    description: str | None
    price: float
    rounded_price: float
    stock: int
    category: str | None = None
    product_type: str | None = None
    model: str | None = None
    image_url: str | None = None
    is_ar_visible: int

    class Config:
        from_attributes = True

