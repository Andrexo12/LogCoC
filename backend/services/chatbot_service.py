import os
import google.generativeai as genai
from sqlalchemy.orm import Session
from models.product import Product
from services.product_service import ProductService

class ChatbotService:
    def __init__(self):
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            # En un entorno real, esto debería lanzar un error, pero para la tesis usamos un placeholder instructivo
            print("⚠️ Advertencia: GEMINI_API_KEY no configurada.")
        
        genai.configure(api_key=api_key)
        self.model = genai.GenerativeModel('gemini-pro')

    async def get_response(self, user_message: str, product_context: str = "") -> str:
        prompt = f"""
        Eres un asesor de ventas experto de 'Innova Center', ubicada en el Orinokia Mall. 
        Tu tono es profesional, servicial y persuasivo.
        
        Contexto del producto actual:
        {product_context}
        
        Reglas importantes:
        1. Si hablas de precios, recuerda que Innova Center redondea al 0.50 superior (ej. 10.15 es 10.50).
        2. Si no conoces un detalle técnico específico, invita al cliente a visitar la tienda física.
        3. Mantén las respuestas concisas pero informativas.
        
        Mensaje del cliente: {user_message}
        """
        
        try:
            response = self.model.generate_content(prompt)
            return response.text
        except Exception as e:
            return f"Lo siento, estoy teniendo dificultades técnicas. ¿Podrías visitarnos en el Orinokia Mall? (Error: {str(e)})"

    @staticmethod
    def format_product_context(product: Product) -> str:
        if not product:
            return "No hay un producto específico seleccionado en este momento."
        
        rounded_price = ProductService.apply_rounding(product.price)
        return f"""
        Producto: {product.name}
        Categoría: {product.category}
        Descripción: {product.description}
        Precio Original: ${product.price}
        Precio Final (Redondeado): ${rounded_price}
        Stock disponible: {product.stock}
        Garantía: 1 año directamente en Innova Center.
        """
