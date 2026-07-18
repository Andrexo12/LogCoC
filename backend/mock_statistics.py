import random
from datetime import datetime, timedelta
from database.db import SessionLocal
from models.product import Product
from models.statistics import ProductView, Sale, ChatbotLog

db = SessionLocal()

products = db.query(Product).all()

if products:
    print("Adding mock product views...")
    for _ in range(50):
        p = random.choice(products)
        view = ProductView(product_id=p.id, timestamp=datetime.utcnow() - timedelta(days=random.randint(0, 30)))
        db.add(view)
        
    print("Adding mock sales...")
    for _ in range(20):
        p = random.choice(products)
        sale = Sale(product_id=p.id, quantity=random.randint(1, 3), timestamp=datetime.utcnow() - timedelta(days=random.randint(0, 30)))
        db.add(sale)

print("Adding mock chatbot logs...")
intents = ['precio', 'disponibilidad', 'garantía', 'horarios', 'ubicación', 'otros']
for _ in range(30):
    intent = random.choice(intents)
    log = ChatbotLog(intent=intent, query_text=f"mock query {intent}", timestamp=datetime.utcnow() - timedelta(days=random.randint(0, 30)))
    db.add(log)

db.commit()
print("Done!")
db.close()
