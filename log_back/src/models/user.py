from pydantic import BaseModel, EmailStr, Field

class UserBase(BaseModel):
    email: EmailStr

    model_config = {
        "from_attributes": True,
    }

class UserCreate(UserBase):
    password: str = Field(..., min_length=8)

class UserLogin(UserBase):
    password: str

class UserResponse(UserBase):
    id: int
    # password no está aquí por seguridad
