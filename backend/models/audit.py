from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.sql import func
from database.db import Base
from pydantic import BaseModel
from typing import Optional

class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    action = Column(String(255), nullable=False)
    target = Column(String(255), nullable=False)
    changes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class ChatbotContext(Base):
    __tablename__ = "chatbot_contexts"

    id = Column(Integer, primary_key=True, index=True)
    context_text = Column(Text, nullable=False)
    created_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

class ChatbotContextBase(BaseModel):
    context_text: str

class ChatbotContextCreate(ChatbotContextBase):
    pass

class ChatbotContextResponse(ChatbotContextBase):
    id: int
    created_by: Optional[int]
    created_at: str | None = None
    updated_at: str | None = None
    user_name: Optional[str] = None # Added manually in response

    model_config = {
        "from_attributes": True,
    }
