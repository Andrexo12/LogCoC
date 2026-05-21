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

from database.db_legacy import Database

@router.post("/ask")
async def ask_bot(request: ChatRequest, db: Session = Depends(get_db)):
    # Obtener datos de entrenamiento personalizados
    db_legacy = Database()
    conn = db_legacy.connect()
    training_context = ""
    if conn:
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT question, answer FROM ai_training")
        rows = cursor.fetchall()
        training_context = "\n".join([f"Q: {r['question']} A: {r['answer']}" for r in rows])
        cursor.close()
        db_legacy.close()

    context = ""
    if request.qr_id:
        product = ProductService.get_product_by_qr(db, request.qr_id)
        if product:
            context = bot_service.format_product_context(product)
    
    response = await bot_service.get_response(
        request.message, 
        product_context=context,
        training_data=training_context
    )
    return {"reply": response}
