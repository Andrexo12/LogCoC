from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database.db import get_db
from models.admin import ARSetting, AITraining
from typing import List, Dict
from routes.auth import require_role

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
