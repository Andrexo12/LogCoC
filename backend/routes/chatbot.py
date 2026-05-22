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
    # 1. Obtener datos de entrenamiento de la base de datos (FAQs y Contexto General)
    db_legacy = Database()
    conn = db_legacy.connect()
    faqs = []
    general_context = ""
    if conn:
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT question, answer, category FROM ai_training")
        rows = cursor.fetchall()
        for r in rows:
            if r.get('category') == 'general_context':
                general_context = r['answer']
            else:
                faqs.append(f"Q: {r['question']} A: {r['answer']}")
        cursor.close()
        db_legacy.close()

    training_context = "\n".join(faqs)

    # 2. Obtener catálogo completo de productos
    catalog_context = ""
    try:
        products = ProductService.get_all_products(db)
        if products:
            catalog_lines = []
            for p in products:
                catalog_lines.append(
                    f"- {p.name} ({p.category}) | Precio: ${p.price} | Stock: {p.stock} | Garantía: 1 año | QR: {p.qr_id} | Descripción: {p.description or 'N/A'}"
                )
            catalog_context = "\n".join(catalog_lines)
    except Exception as e:
        print(f"Error obteniendo catálogo de productos: {e}")

    # 3. Contexto del producto actual escaneado por QR
    context = ""
    if request.qr_id:
        product = ProductService.get_product_by_qr(db, request.qr_id)
        if product:
            context = bot_service.format_product_context(product)
    
    # 4. Obtener respuesta enriquecida del Chatbot
    response = await bot_service.get_response(
        request.message, 
        product_context=context,
        catalog_context=catalog_context,
        general_context=general_context,
        training_data=training_context
    )
    return {"reply": response}
