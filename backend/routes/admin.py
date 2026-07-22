from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database.db import get_db
from models.admin import ARSetting, AITraining
from models.audit import ChatbotContext, ChatbotContextCreate, ChatbotContextResponse
from typing import List, Dict
from routes.auth import require_role
from routes.audit import log_action

router = APIRouter(prefix="/admin", tags=["Admin Settings"])

@router.get("/ar-settings")
def get_ar_settings(db: Session = Depends(get_db), current_user = Depends(require_role("admin"))):
    return db.query(ARSetting).all()

@router.post("/ar-settings/toggle")
def toggle_ar_setting(section_name: str, is_enabled: bool, db: Session = Depends(get_db), current_user = Depends(require_role("admin"))):
    setting = db.query(ARSetting).filter(ARSetting.section_name == section_name).first()
    if not setting:
        raise HTTPException(status_code=404, detail="Configuración no encontrada")
    
    setting.is_enabled = 1 if is_enabled else 0
    db.commit()
    return {"message": f"Setting {section_name} updated"}

@router.post("/ai-training")
def add_ai_training(data: Dict[str, str], db: Session = Depends(get_db), current_user = Depends(require_role("admin"))):
    category = data.get("category", "general")
    question = data.get("question", "")
    answer = data.get("answer", "")

    if category == "general_context":
        item = db.query(AITraining).filter(AITraining.category == "general_context").first()
        if item:
            item.answer = answer
            item.question = question
        else:
            item = AITraining(question=question, answer=answer, category="general_context")
            db.add(item)
    elif category == "campaign_percentage":
        item = db.query(AITraining).filter(AITraining.category == "campaign_percentage").first()
        if item:
            item.answer = answer
            item.question = question
        else:
            item = AITraining(question=question, answer=answer, category="campaign_percentage")
            db.add(item)
    else:
        item = AITraining(question=question, answer=answer, category=category)
        db.add(item)
    
    db.commit()
    return {"message": "AI training data added/updated", "success": True}

@router.get("/ai-training")
def get_ai_training(db: Session = Depends(get_db), current_user = Depends(require_role("admin"))):
    return db.query(AITraining).order_by(AITraining.created_at.desc()).all()

@router.delete("/ai-training/{item_id}")
def delete_ai_training(item_id: int, db: Session = Depends(get_db), current_user = Depends(require_role("admin"))):
    item = db.query(AITraining).filter(AITraining.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item no encontrado")
    
    db.delete(item)
    db.commit()
    return {"message": "AI training data deleted"}

@router.post("/ai-training/chat")
def train_bot_chat(data: Dict[str, str], db: Session = Depends(get_db), current_user = Depends(require_role("admin"))):
    instruction = data.get("instruction", "")
    if not instruction:
        raise HTTPException(status_code=400, detail="Falta instrucción")

    item = db.query(AITraining).filter(AITraining.category == "general_context").first()
    current_context = item.answer if item else "Innova Center es una tienda de tecnología."

    import os
    from groq import Groq
    api_key = os.getenv("GROQ_API_KEY")
    if not api_key:
        raise HTTPException(status_code=500, detail="GROQ_API_KEY no configurado")
    
    client = Groq(api_key=api_key)
    
    prompt = f"""
    Eres un meta-entrenador de IA. Tu tarea es actualizar las instrucciones y el "cerebro" del chatbot de atención al cliente basándote en la orden del administrador.
    
    Contexto o cerebro actual del chatbot:
    \"\"\"{current_context}\"\"\"
    
    Instrucción nueva del administrador:
    \"\"\"{instruction}\"\"\"
    
    Reescribe el contexto general completo incorporando inteligentemente las nuevas instrucciones. 
    Mantén el formato profesional. Si la instrucción pide reglas matemáticas (ej: calcular BCV a 1.85, descuentos, precios), escríbelas claramente para que el chatbot las siga al pie de la letra. 
    Devuelve SOLO el texto resultante del nuevo contexto, sin comillas, saludos ni confirmaciones.
    """
    
    try:
        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[{"role": "user", "content": prompt}]
        )
        new_context = response.choices[0].message.content.strip()
        
        if item:
            item.answer = new_context
            item.question = "Contexto Generado por Entrenador IA"
        else:
            item = AITraining(question="Contexto Generado por Entrenador IA", answer=new_context, category="general_context")
            db.add(item)
            
        db.commit()
        return {"message": "El chatbot ha aprendido la nueva instrucción exitosamente.", "new_context": new_context, "success": True}
    except Exception as e:
        print(f"Error entrenando bot: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/chatbot-contexts", response_model=List[ChatbotContextResponse])
def get_chatbot_contexts(db: Session = Depends(get_db), current_user = Depends(require_role("admin"))):
    from models.user import User
    contexts = db.query(ChatbotContext, User).outerjoin(User, ChatbotContext.created_by == User.id).order_by(ChatbotContext.created_at.desc()).all()
    result = []
    for ctx, user in contexts:
        ctx_dict = ctx.__dict__.copy()
        if user:
            name = f"{user.first_name or ''} {user.last_name or ''}".strip()
            ctx_dict["user_name"] = name if name else user.email
        else:
            ctx_dict["user_name"] = "Desconocido"
        # Format dates as strings to satisfy Pydantic if needed
        if ctx_dict.get("created_at"): ctx_dict["created_at"] = ctx_dict["created_at"].isoformat()
        if ctx_dict.get("updated_at"): ctx_dict["updated_at"] = ctx_dict["updated_at"].isoformat()
        result.append(ctx_dict)
    return result

@router.post("/chatbot-contexts", response_model=ChatbotContextResponse)
def create_chatbot_context(data: ChatbotContextCreate, db: Session = Depends(get_db), current_user = Depends(require_role("admin"))):
    new_ctx = ChatbotContext(context_text=data.context_text, created_by=current_user.id)
    db.add(new_ctx)
    db.commit()
    db.refresh(new_ctx)
    log_action(db, current_user.id, "CREAR_CONTEXTO", "Chatbot", "Se agregó un nuevo contexto al chatbot")
    
    ctx_dict = new_ctx.__dict__.copy()
    name = f"{current_user.first_name or ''} {current_user.last_name or ''}".strip()
    ctx_dict["user_name"] = name if name else current_user.email
    if ctx_dict.get("created_at"): ctx_dict["created_at"] = ctx_dict["created_at"].isoformat()
    if ctx_dict.get("updated_at"): ctx_dict["updated_at"] = ctx_dict["updated_at"].isoformat()
    return ctx_dict

@router.put("/chatbot-contexts/{ctx_id}", response_model=ChatbotContextResponse)
def update_chatbot_context(ctx_id: int, data: ChatbotContextCreate, db: Session = Depends(get_db), current_user = Depends(require_role("admin"))):
    ctx = db.query(ChatbotContext).filter(ChatbotContext.id == ctx_id).first()
    if not ctx:
        raise HTTPException(status_code=404, detail="Contexto no encontrado")
    
    ctx.context_text = data.context_text
    ctx.created_by = current_user.id  # Update who last modified it, or keep original? Update it.
    db.commit()
    db.refresh(ctx)
    log_action(db, current_user.id, "EDITAR_CONTEXTO", "Chatbot", f"Se editó el contexto ID: {ctx_id}")
    
    ctx_dict = ctx.__dict__.copy()
    name = f"{current_user.first_name or ''} {current_user.last_name or ''}".strip()
    ctx_dict["user_name"] = name if name else current_user.email
    if ctx_dict.get("created_at"): ctx_dict["created_at"] = ctx_dict["created_at"].isoformat()
    if ctx_dict.get("updated_at"): ctx_dict["updated_at"] = ctx_dict["updated_at"].isoformat()
    return ctx_dict

@router.delete("/chatbot-contexts/{ctx_id}")
def delete_chatbot_context(ctx_id: int, db: Session = Depends(get_db), current_user = Depends(require_role("admin"))):
    ctx = db.query(ChatbotContext).filter(ChatbotContext.id == ctx_id).first()
    if not ctx:
        raise HTTPException(status_code=404, detail="Contexto no encontrado")
    
    db.delete(ctx)
    db.commit()
    log_action(db, current_user.id, "ELIMINAR_CONTEXTO", "Chatbot", f"Se eliminó el contexto ID: {ctx_id}")
    return {"success": True, "message": "Contexto eliminado"}
