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

    async def get_response(
        self, 
        user_message: str, 
        product_context: str = "", 
        catalog_context: str = "",
        general_context: str = "",
        training_data: str = ""
    ) -> str:
        system_prompt = f"""
        Eres un asesor de ventas experto de 'Innova Center', ubicada en el Orinokia Mall. 
        Tu tono es profesional, servicial y persuasivo.
        
        === CONTEXTO GENERAL DEL NEGOCIO / POLÍTICAS ===
        {general_context or "Innova Center es una tienda de tecnología premium ubicada en el Orinokia Mall."}
        
        === CATÁLOGO DE PRODUCTOS DISPONIBLES EN TIENDA ===
        {catalog_context or "No hay un catálogo de productos cargado actualmente."}
        
        === PRODUCTO ESPECÍFICO CONSULTADO (Si aplica) ===
        {product_context}

        === PREGUNTAS FRECUENTES Y CONOCIMIENTOS ADICIONALES ===
        {training_data}
        
        === REGLAS IMPORTANTES DE RESPUESTA ===
        1. Si el cliente pregunta sobre precios de productos específicos del catálogo o del producto actual, recuerda aplicar la regla de redondeo de Innova Center: redondea al 0.50 superior (ej. 10.15 se convierte en 10.50, 15.00 queda en 15.00, 12.60 se convierte en 13.00, etc.). Presenta siempre el precio redondeado de manera persuasiva.
        2. Basa tus respuestas estrictamente en el Catálogo de Productos y en el Contexto del Negocio proporcionados arriba. No inventes productos ni stock que no estén explícitamente listados.
        3. Si te preguntan si un producto está disponible, revisa el catálogo. Si tiene Stock > 0, confirma la disponibilidad. Si Stock es 0 o no está en el catálogo, indica amablemente que no está en stock actualmente pero que pueden visitarnos para ver alternativas.
        4. Si no conoces un detalle técnico o respuesta a una pregunta, invita cordialmente al cliente a visitar la tienda física en el Orinokia Mall.
        5. Mantén las respuestas concisas pero informativas y profesionales.
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
