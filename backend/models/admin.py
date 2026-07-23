from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database.db import Base
from models.lookup import CategoriaIA

class ARSetting(Base):
    __tablename__ = "configuracion_ra"

    id = Column("id", Integer, primary_key=True, index=True)
    section_name = Column("nombre_seccion", String(100), unique=True, nullable=False)
    is_enabled = Column("esta_habilitado", Integer, default=1)

class AITraining(Base):
    __tablename__ = "entrenamiento_ia"

    id = Column("id", Integer, primary_key=True, index=True)
    question = Column("pregunta", Text, nullable=False)
    answer = Column("respuesta", Text, nullable=False)
    category_id = Column("id_categoria_ia", Integer, ForeignKey("categorias_ia.id"), nullable=True)
    created_at = Column("fecha_creacion", DateTime(timezone=True), server_default=func.now())

    category_rel = relationship("CategoriaIA")

    @property
    def category(self) -> str:
        return self.category_rel.nombre if self.category_rel else None
