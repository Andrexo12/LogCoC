from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database.db_legacy import Database
from database.db import get_db
from typing import List, Dict

router = APIRouter(prefix="/admin", tags=["Admin Settings"])

@router.get("/ar-settings")
def get_ar_settings():
    db_legacy = Database()
    conn = db_legacy.connect()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM ar_settings")
    settings = cursor.fetchall()
    cursor.close()
    db_legacy.close()
    return settings

@router.post("/ar-settings/toggle")
def toggle_ar_setting(section_name: str, is_enabled: bool):
    db_legacy = Database()
    conn = db_legacy.connect()
    cursor = conn.cursor()
    cursor.execute(
        "UPDATE ar_settings SET is_enabled = %s WHERE section_name = %s",
        (1 if is_enabled else 0, section_name)
    )
    conn.commit()
    cursor.close()
    db_legacy.close()
    return {"message": f"Setting {section_name} updated"}

@router.post("/ai-training")
def add_ai_training(data: Dict[str, str]):
    db_legacy = Database()
    conn = db_legacy.connect()
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO ai_training (question, answer, category) VALUES (%s, %s, %s)",
        (data["question"], data["answer"], data.get("category", "general"))
    )
    conn.commit()
    cursor.close()
    db_legacy.close()
    return {"message": "AI training data added"}

@router.get("/ai-training")
def get_ai_training():
    db_legacy = Database()
    conn = db_legacy.connect()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM ai_training ORDER BY created_at DESC")
    training_data = cursor.fetchall()
    cursor.close()
    db_legacy.close()
    return training_data
