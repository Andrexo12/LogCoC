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

class ProductSchema(BaseModel):
    id: int
    qr_id: str
    name: str
    description: str | None
    price: float
    rounded_price: float
    stock: int
    category: str | None

    class Config:
        from_attributes = True
