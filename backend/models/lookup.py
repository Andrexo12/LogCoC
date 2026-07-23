from sqlalchemy import Column, Integer, String
from database.db import Base

class Role(Base):
    __tablename__ = "roles"
    id = Column("id", Integer, primary_key=True, index=True)
    nombre = Column("nombre", String(50), unique=True, nullable=False)

class Categoria(Base):
    __tablename__ = "categorias"
    id = Column("id", Integer, primary_key=True, index=True)
    nombre = Column("nombre", String(100), unique=True, nullable=False)

class TipoProducto(Base):
    __tablename__ = "tipos_producto"
    id = Column("id", Integer, primary_key=True, index=True)
    nombre = Column("nombre", String(100), unique=True, nullable=False)

class CategoriaIA(Base):
    __tablename__ = "categorias_ia"
    id = Column("id", Integer, primary_key=True, index=True)
    nombre = Column("nombre", String(100), unique=True, nullable=False)
