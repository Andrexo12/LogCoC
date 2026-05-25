from sqlalchemy import Column, Integer, String, Float, Text
from database.db import Base
from pydantic import BaseModel

class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)
    qr_id = Column(String(100), unique=True, index=True, nullable=False)
    name = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    price = Column(Float, nullable=False)
    stock = Column(Integer, default=0)
    category = Column(String(100), nullable=True)
    product_type = Column(String(100), nullable=True) # linea blanca, gris, electro
    image_url = Column(Text, nullable=True)
    is_ar_visible = Column(Integer, default=1) # 1 visible, 0 oculto

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
    category: str | None
    product_type: str | None
    image_url: str | None = None
    is_ar_visible: int

    class Config:
        from_attributes = True
