from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from datetime import datetime
from database.db import Base

class ProductView(Base):
    __tablename__ = "product_views"
    
    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id", ondelete="CASCADE"), nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)
    # Si quisieras trackear usuarios, podrías añadir user_id
    
    product = relationship("Product")

class Sale(Base):
    __tablename__ = "sales"
    
    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id", ondelete="CASCADE"), nullable=False)
    quantity = Column(Integer, nullable=False, default=1)
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)
    
    product = relationship("Product")

class ChatbotLog(Base):
    __tablename__ = "chatbot_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    intent = Column(String(100), nullable=False, index=True) # ej: "precio", "horarios", "garantia"
    query_text = Column(Text, nullable=True) # lo que el usuario escribió realmente
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)
