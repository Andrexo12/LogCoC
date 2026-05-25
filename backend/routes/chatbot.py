from fastapi import APIRouter, Depends, Body
from sqlalchemy.orm import Session
from database.db import get_db
from services.chatbot_service import ChatbotService
from services.product_service import ProductService
from models.admin import AITraining
from pydantic import BaseModel

router = APIRouter(prefix="/chatbot", tags=["Chatbot"])

class ChatRequest(BaseModel):
    message: str
    qr_id: str | None = None

@router.post("/ask")
async def ask_bot(request: ChatRequest, db: Session = Depends(get_db)):
    bot_service = ChatbotService()
    # 1. Obtener datos de entrenamiento de la base de datos (FAQs y Contexto General)
    training_rows = db.query(AITraining).all()
    faqs = []
    general_context = ""
    for r in training_rows:
        if r.category == 'general_context':
            general_context = r.answer
        elif r.category == 'campaign_percentage':
            continue # Opcional: manejar porcentaje aparte si se desea
        else:
            faqs.append(f"Q: {r.question} A: {r.answer}")

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

