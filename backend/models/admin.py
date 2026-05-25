from sqlalchemy import Column, Integer, String, Text, DateTime
from sqlalchemy.sql import func
from database.db import Base

class ARSetting(Base):
    __tablename__ = "ar_settings"

    id = Column(Integer, primary_key=True, index=True)
    section_name = Column(String(100), unique=True, nullable=False)
    is_enabled = Column(Integer, default=1)

class AITraining(Base):
    __tablename__ = "ai_training"

    id = Column(Integer, primary_key=True, index=True)
    question = Column(Text, nullable=False)
    answer = Column(Text, nullable=False)
    category = Column(String(100), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
