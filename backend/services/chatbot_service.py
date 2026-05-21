import os
from groq import Groq
from sqlalchemy.orm import Session
from models.product import Product
from services.product_service import ProductService

class ChatbotService:
    def __init__(self):
        api_key = os.getenv("GROQ_API_KEY")
        if not api_key:
            print("⚠️ Advertencia: GROQ_API_KEY no configurada.")
        
        self.client = Groq(api_key=api_key)
        # Usamos Llama 3.3 70B para una calidad similar o superior a Gemini
        self.model = "llama-3.3-70b-versatile"

    async def get_response(self, user_message: str, product_context: str = "", training_data: str = "") -> str:
        system_prompt = f"""
        Eres un asesor de ventas experto de 'Innova Center', ubicada en el Orinokia Mall. 
        Tu tono es profesional, servicial y persuasivo.
        
        Contexto del producto actual:
        {product_context}

        Respuestas predeterminadas y conocimientos específicos:
        {training_data}
        
        Reglas importantes:
        1. Si hablas de precios, recuerda que Innova Center redondea al 0.50 superior (ej. 10.15 es 10.50).
        2. Si una pregunta coincide con el conocimiento específico proporcionado arriba, úsalo.
        3. Si no conoces un detalle técnico específico, invita al cliente a visitar la tienda física.
        4. Mantén las respuestas concisas pero informativas.
        """
        
        try:
            chat_completion = self.client.chat.completions.create(
                messages=[
                    {
                        "role": "system",
                        "content": system_prompt,
                    },
                    {
                        "role": "user",
                        "content": user_message,
                    }
                ],
                model=self.model,
            )
            return chat_completion.choices[0].message.content
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
