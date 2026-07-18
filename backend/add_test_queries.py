import os
import sys

# Add the current directory to sys.path so we can import modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from database.db import SessionLocal
from models.product import Product
from models.statistics import ProductView, Sale, ChatbotLog

def test_queries():
    db = SessionLocal()
    from routes.chatbot import ChatRequest
    from models.statistics import ChatbotLog
    import re
    # We will simulate 3 messages about "precio", 2 about "stock", 1 "ubicacion"
    queries = [
        "hola, quisiera saber el precio de este producto",
        "cuál es el precio de esto?",
        "precio por favor",
        "tienen stock disponible?",
        "hay stock?",
        "dónde es la ubicación de la tienda",
    ]
    
    for q in queries:
        msg_lower = q.lower()
        msg_clean = re.sub(r'[^\w\s]', '', msg_lower)
        words = msg_clean.split()
        stop_words = {"hola", "buenas", "tardes", "dias", "noches", "gracias", "por", "favor", 
                      "el", "la", "los", "las", "un", "una", "unos", "unas", "qué", "que", "como", 
                      "cuando", "donde", "para", "con", "de", "del", "a", "al", "es", "esta", 
                      "estan", "son", "tiene", "tienen", "quiero", "saber", "me", "te", "se", 
                      "nos", "y", "o", "en", "su", "sus", "tu", "tus", "mi", "mis", "muy", "mucho",
                      "quisiera", "ayuda", "podrias", "puedes", "holaa", "buenos", "cuál"}
        keywords = [w for w in words if w not in stop_words and len(w) > 2]
        intent = keywords[0] if keywords else "general"
        log = ChatbotLog(intent=intent, query_text=q)
        db.add(log)
    db.commit()
    print("Test queries added.")
    db.close()

if __name__ == "__main__":
    test_queries()
