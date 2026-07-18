import os
import sys

# Add the current directory to sys.path so we can import modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from models.product import Product
from database.db import SessionLocal
from models.statistics import ProductView, Sale, ChatbotLog

def clear_data():
    db = SessionLocal()
    try:
        # Delete all records from these tables
        db.query(ProductView).delete()
        db.query(Sale).delete()
        db.query(ChatbotLog).delete()
        db.commit()
        print("Mock data cleared successfully.")
    except Exception as e:
        db.rollback()
        print(f"Error clearing mock data: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    clear_data()
