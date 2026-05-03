from fastapi import APIRouter, Depends, Body
from sqlalchemy.orm import Session
from database.db import get_db
from services.chatbot_service import ChatbotService
from services.product_service import ProductService
from pydantic import BaseModel

router = APIRouter(prefix="/chatbot", tags=["Chatbot"])
bot_service = ChatbotService()

class ChatRequest(BaseModel):
    message: str
    qr_id: str | None = None

@router.post("/ask")
async def ask_bot(request: ChatRequest, db: Session = Depends(get_db)):
    context = ""
    if request.qr_id:
        product = ProductService.get_product_by_qr(db, request.qr_id)
        if product:
            context = bot_service.format_product_context(product)
    
    response = await bot_service.get_response(request.message, context)
    return {"reply": response}
