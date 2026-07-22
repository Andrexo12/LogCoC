from pydantic import BaseModel, EmailStr, Field
from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.sql import func
from database.db import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    first_name = Column(String(100), nullable=True)
    last_name = Column(String(100), nullable=True)
    role = Column(String(50), default="scanner")
    status = Column(String(50), default="approved") # 'pending' or 'approved'
    created_at = Column(DateTime(timezone=True), server_default=func.now())

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
