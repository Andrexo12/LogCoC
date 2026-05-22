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
    cursor = conn.cursor(dictionary=True)
    category = data.get("category", "general")
    if category == "general_context":
        cursor.execute("SELECT id FROM ai_training WHERE category = 'general_context'")
        row = cursor.fetchone()
        if row:
            cursor.execute(
                "UPDATE ai_training SET answer = %s, question = %s WHERE id = %s",
                (data["answer"], data["question"], row["id"])
            )
        else:
            cursor.execute(
                "INSERT INTO ai_training (question, answer, category) VALUES (%s, %s, %s)",
                (data["question"], data["answer"], "general_context")
            )
    else:
        cursor.execute(
            "INSERT INTO ai_training (question, answer, category) VALUES (%s, %s, %s)",
            (data["question"], data["answer"], category)
        )
    conn.commit()
    cursor.close()
    db_legacy.close()
    return {"message": "AI training data added/updated"}

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

@router.delete("/ai-training/{item_id}")
def delete_ai_training(item_id: int):
    db_legacy = Database()
    conn = db_legacy.connect()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM ai_training WHERE id = %s", (item_id,))
    conn.commit()
    cursor.close()
    db_legacy.close()
    return {"message": "AI training data deleted"}
