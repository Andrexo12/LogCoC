from fastapi import APIRouter, Depends, Body
from sqlalchemy.orm import Session
from database.db import get_db
from services.chatbot_service import ChatbotService
from services.product_service import ProductService
from models.admin import AITraining
from models.audit import ChatbotContext
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
    
    # 1.b Obtener los contextos agregados manualmente
    context_rows = db.query(ChatbotContext).all()
    general_context_lines = []
    for ctx in context_rows:
        general_context_lines.append(ctx.context_text)
        
    for r in training_rows:
        if r.category == 'general_context':
            general_context_lines.append(r.answer)
        elif r.category == 'campaign_percentage':
            continue # Opcional: manejar porcentaje aparte si se desea
        else:
            faqs.append(f"Q: {r.question} A: {r.answer}")

    general_context = "\n".join(general_context_lines)
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
    
    # 5. Registrar en estadísticas
    from models.statistics import ChatbotLog
    import re
    msg_lower = request.message.lower()
    
    msg_clean = re.sub(r'[^\w\s]', '', msg_lower)
    words = msg_clean.split()
    
    stop_words = {"hola", "buenas", "tardes", "dias", "noches", "gracias", "por", "favor", 
                  "el", "la", "los", "las", "un", "una", "unos", "unas", "qué", "que", "como", 
                  "cuando", "donde", "para", "con", "de", "del", "a", "al", "es", "esta", 
                  "estan", "son", "tiene", "tienen", "quiero", "saber", "me", "te", "se", 
                  "nos", "y", "o", "en", "su", "sus", "tu", "tus", "mi", "mis", "muy", "mucho",
                  "quisiera", "ayuda", "podrias", "puedes", "holaa", "buenos"}
                  
    keywords = [w for w in words if w not in stop_words and len(w) > 2]
    
    # Tomar la palabra más representativa o "general"
    intent = keywords[0] if keywords else "general"

    try:
        new_log = ChatbotLog(intent=intent, query_text=request.message)
        db.add(new_log)
        db.commit()
    except Exception as e:
        print(f"Error registrando estadística de chatbot: {e}")

    return {"reply": response}
