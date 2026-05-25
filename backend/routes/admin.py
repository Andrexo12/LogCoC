from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database.db import get_db
from models.admin import ARSetting, AITraining
from typing import List, Dict

router = APIRouter(prefix="/admin", tags=["Admin Settings"])

@router.get("/ar-settings")
def get_ar_settings(db: Session = Depends(get_db)):
    return db.query(ARSetting).all()

@router.post("/ar-settings/toggle")
def toggle_ar_setting(section_name: str, is_enabled: bool, db: Session = Depends(get_db)):
    setting = db.query(ARSetting).filter(ARSetting.section_name == section_name).first()
    if not setting:
        raise HTTPException(status_code=404, detail="Configuración no encontrada")
    
    setting.is_enabled = 1 if is_enabled else 0
    db.commit()
    return {"message": f"Setting {section_name} updated"}

@router.post("/ai-training")
def add_ai_training(data: Dict[str, str], db: Session = Depends(get_db)):
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
def get_ai_training(db: Session = Depends(get_db)):
    return db.query(AITraining).order_by(AITraining.created_at.desc()).all()

@router.delete("/ai-training/{item_id}")
def delete_ai_training(item_id: int, db: Session = Depends(get_db)):
    item = db.query(AITraining).filter(AITraining.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item no encontrado")
    
    db.delete(item)
    db.commit()
    return {"message": "AI training data deleted"}

