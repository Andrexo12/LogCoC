from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.sql import func
from database.db import Base
from pydantic import BaseModel
from typing import Optional

class AuditLog(Base):
    __tablename__ = "auditoria"

    id = Column("id", Integer, primary_key=True, index=True)
    user_id = Column("id_usuario", Integer, ForeignKey("usuarios.id"), nullable=True)
    action = Column("accion", String(255), nullable=False)
    target = Column("objetivo", String(255), nullable=False)
    changes = Column("cambios", Text, nullable=True)
    created_at = Column("fecha_hora", DateTime(timezone=True), server_default=func.now())

class ChatbotContext(Base):
    __tablename__ = "contexto_chatbot"

    id = Column("id", Integer, primary_key=True, index=True)
    context_text = Column("texto_contexto", Text, nullable=False)
    created_by = Column("creado_por", Integer, ForeignKey("usuarios.id"), nullable=True)
    created_at = Column("fecha_creacion", DateTime(timezone=True), server_default=func.now())
    updated_at = Column("fecha_actualizacion", DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

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
