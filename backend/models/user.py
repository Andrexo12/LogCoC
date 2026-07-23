from pydantic import BaseModel, EmailStr, Field
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database.db import Base
from models.lookup import Role

class User(Base):
    __tablename__ = "usuarios"

    id = Column("id", Integer, primary_key=True, index=True)
    email = Column("correo", String(255), unique=True, index=True, nullable=False)
    password_hash = Column("hash_contrasena", String(255), nullable=False)
    first_name = Column("nombre", String(100), nullable=True)
    last_name = Column("apellido", String(100), nullable=True)
    role_id = Column("id_rol", Integer, ForeignKey("roles.id"), nullable=True)
    status = Column("estado", String(50), default="approved") # 'pending' or 'approved'
    created_at = Column("fecha_creacion", DateTime(timezone=True), server_default=func.now())

    role_rel = relationship("Role")

    @property
    def role(self) -> str:
        return self.role_rel.nombre if self.role_rel else "scanner"

class UserBase(BaseModel):
    email: EmailStr
    first_name: str | None = None
    last_name: str | None = None
    role: str = "scanner"  # 'admin' o 'scanner'
    status: str = "approved"

    model_config = {
        "from_attributes": True,
    }

class UserCreate(UserBase):
    password: str = Field(..., min_length=8)

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(UserBase):
    id: int

