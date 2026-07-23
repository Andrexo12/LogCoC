from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from datetime import datetime
from database.db import Base

class ProductView(Base):
    __tablename__ = "vistas_producto"
    
    id = Column("id", Integer, primary_key=True, index=True)
    product_id = Column("id_producto", Integer, ForeignKey("productos.id", ondelete="CASCADE"), nullable=False)
    timestamp = Column("fecha_hora", DateTime, default=datetime.utcnow, index=True)
    
    product = relationship("Product")

class Sale(Base):
    __tablename__ = "ventas"
    
    id = Column("id", Integer, primary_key=True, index=True)
    product_id = Column("id_producto", Integer, ForeignKey("productos.id", ondelete="CASCADE"), nullable=False)
    quantity = Column("cantidad", Integer, nullable=False, default=1)
    timestamp = Column("fecha_hora", DateTime, default=datetime.utcnow, index=True)
    
    product = relationship("Product")

class ChatbotLog(Base):
    __tablename__ = "registros_chatbot"
    
    id = Column("id", Integer, primary_key=True, index=True)
    intent = Column("intencion", String(100), nullable=False, index=True) # ej: "precio", "horarios", "garantia"
    query_text = Column("texto_consulta", Text, nullable=True) # lo que el usuario escribió realmente
    timestamp = Column("fecha_hora", DateTime, default=datetime.utcnow, index=True)
