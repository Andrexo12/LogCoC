from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func, desc
from database.db import get_db
from models.product import Product
from models.statistics import ProductView, Sale, ChatbotLog
from routes.auth import get_current_user
from models.user import User

router = APIRouter()

@router.get("/dashboard")
def get_statistics_dashboard(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """
    Returns aggregated statistics for the admin dashboard.
    Only accessible to admins.
    """
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized")

    # 1. Most searched/viewed products (Top 10)
    most_searched_query = db.query(
        Product.id, Product.name, Product.qr_id, Product.image_url, func.count(ProductView.id).label("views_count")
    ).join(ProductView, Product.id == ProductView.product_id)\
     .group_by(Product.id)\
     .order_by(desc("views_count"))\
     .limit(10).all()

    most_searched = [
        {"id": row.id, "name": row.name, "qr_id": row.qr_id, "image_url": row.image_url, "views": row.views_count}
        for row in most_searched_query
    ]



    # 3. Frequent Chatbot Questions (Top 10 intents)
    frequent_questions_query = db.query(
        ChatbotLog.intent, func.count(ChatbotLog.id).label("intent_count")
    ).group_by(ChatbotLog.intent)\
     .order_by(desc("intent_count"))\
     .limit(10).all()

    frequent_questions = [
        {"intent": row.intent, "count": row.intent_count}
        for row in frequent_questions_query
    ]

    # 4. Stock Status
    total_products = db.query(func.count(Product.id)).scalar()
    out_of_stock = db.query(func.count(Product.id)).filter(Product.stock == 0).scalar()
    low_stock = db.query(func.count(Product.id)).filter(Product.stock > 0, Product.stock <= 5).scalar()
    
    # Products with lowest stock
    critical_stock_query = db.query(
        Product.id, Product.name, Product.qr_id, Product.stock, Product.image_url
    ).filter(Product.stock <= 5)\
     .order_by(Product.stock.asc())\
     .limit(5).all()
    
    critical_stock = [
        {"id": row.id, "name": row.name, "qr_id": row.qr_id, "stock": row.stock, "image_url": row.image_url}
        for row in critical_stock_query
    ]

    stock_status = {
        "total": total_products,
        "out_of_stock": out_of_stock,
        "low_stock": low_stock,
        "critical_products": critical_stock
    }

    # Return unified payload
    return {
        "most_searched": most_searched,
        "frequent_questions": frequent_questions,
        "stock_status": stock_status
    }

@router.post("/events/view/{product_id}")
def log_product_view(product_id: int, db: Session = Depends(get_db)):
    """Logs a product view event (used by mobile/web apps)."""
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    new_view = ProductView(product_id=product_id)
    db.add(new_view)
    db.commit()
    return {"message": "View logged"}

@router.post("/events/sale/{product_id}")
def log_product_sale(product_id: int, quantity: int = 1, db: Session = Depends(get_db)):
    """Logs a product sale (mock endpoint for now, should be tied to real checkout)."""
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    new_sale = Sale(product_id=product_id, quantity=quantity)
    # Actually reduce stock
    product.stock -= quantity
    if product.stock < 0:
        product.stock = 0
        
    db.add(new_sale)
    db.commit()
    return {"message": "Sale logged and stock updated"}

@router.get("/chatbot-logs/{intent}")
def get_chatbot_logs_by_intent(intent: str, limit: int = 5, offset: int = 0, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """Fetches real queries for a given intent (keyword) with pagination."""
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized")
    
    logs_query = db.query(ChatbotLog).filter(ChatbotLog.intent == intent).order_by(desc(ChatbotLog.timestamp))
    total = logs_query.count()
    logs = logs_query.offset(offset).limit(limit).all()
    
    return {
        "intent": intent,
        "total": total,
        "logs": [
            {
                "id": log.id,
                "query_text": log.query_text,
                "timestamp": log.timestamp
            } for log in logs
        ]
    }
