import os
from groq import Groq
from sqlalchemy.orm import Session
from models.product import Product
from services.product_service import ProductService
from utils.validation import is_valid_key

class ChatbotService:
    def __init__(self):
        from dotenv import load_dotenv
        load_dotenv(override=True)
        
        self.groq_key = os.getenv("GROQ_API_KEY")
        
        self.groq_valid = is_valid_key(self.groq_key)
        
        self.client = None
        if self.groq_valid:
            try:
                self.client = Groq(api_key=self.groq_key)
            except Exception as e:
                print(f"Error instanciando Groq: {e}")
                self.groq_valid = False
        
        self.model = "llama-3.3-70b-versatile"

    # Deprecated validation method moved to utils.validation.is_valid_key

    async def get_response(
        self, 
        user_message: str, 
        product_context: str = "", 
        catalog_context: str = "",
        general_context: str = "",
        training_data: str = ""
    ) -> str:
        # Si no hay llaves válidas configuradas, usar el mock-fallback inteligente
        if not self.groq_valid:
            return self._get_mocked_fallback_response(user_message, product_context, catalog_context)
            
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
        
        === REGLAS IMPORTANTES DE RESPUESTA (ESTRICTAS) ===
        1. PROHIBIDO USAR ASTERISCOS: No uses formato markdown de negrita ni cursiva (* o **).
        2. EL PRECIO BASE ES DIVISAS: El "Precio Base en Divisas (USD)" que ves en el contexto es el precio en dólares. SOLO dáselo al cliente si pregunta EXPRESAMENTE por el precio en divisas o dólares.
        3. CÁLCULO INVISIBLE DEL PRECIO BOLÍVARES: Para dar el precio normal, toma el Precio Base en Divisas, multiplícalo por la tasa del contexto general (ej. 1.85) y aplica redondeo al 0.50 superior. Este es tu "Precio General Bolívares". NUNCA muestres esta operación matemática ni signos como =, *, +.
        4. CÁLCULO INVISIBLE DEL DESCUENTO: Si hay un descuento en el contexto (ej. 10%), aplícalo SOLO al "Precio General Bolívares" calculado en el paso anterior. Este descuento es EXCLUSIVO para pagos en bolívares. Nunca le quites el 10% al precio en divisas.
        5. PRESENTACIÓN EXACTA: Da la respuesta usando ÚNICAMENTE los resultados en bolívares y con esta estructura textual exacta: "Su precio es $[Precio General Bolívares]. Y, actualmente, por lista tiene un descuento específico, quedando en $[Precio Descuento Bolívares]."
        6. NO EXPLIQUES NADA: No uses las palabras "divisas" o "bolívares" en el mensaje por defecto. No expliques que hay una tasa cambiaria. Solo da la respuesta exacta de la regla 5.
        7. Basa tus respuestas estrictamente en el Catálogo de Productos y en el Contexto proporcionado.
        8. Si te preguntan por disponibilidad, revisa el catálogo. Si tiene Stock > 0, confirma la disponibilidad. Si no hay, invita amablemente a la tienda a ver alternativas.
        9. Si no conoces un detalle, invita al cliente a visitar la tienda física en el Orinokia Mall. Mantén la fluidez conversacional.
        """
        
        # Intentar con Groq si es válido
        if self.groq_valid and self.client:
            try:
                chat_completion = self.client.chat.completions.create(
                    messages=[
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": user_message}
                    ],
                    model=self.model,
                )
                return chat_completion.choices[0].message.content
            except Exception as e:
                print(f"Groq Chat failed: {e}.")
                 
        return self._get_mocked_fallback_response(user_message, product_context, catalog_context)

    def _get_mocked_fallback_response(self, user_message: str, product_context: str, catalog_context: str) -> str:
        user_lower = user_message.lower()
        
        # Procesar contexto de producto si está disponible
        product_info = None
        if product_context and "Producto:" in product_context:
            lines = [line.strip() for line in product_context.strip().split("\n") if line.strip()]
            product_info = {}
            for line in lines:
                if ":" in line:
                    parts = line.split(":", 1)
                    key = parts[0].strip().lower()
                    val = parts[1].strip()
                    product_info[key] = val

        if product_info and "producto" in product_info:
            prod_name = product_info.get("producto", "producto escaneado")
            category = product_info.get("categoría", "Innova Center")
            price_final = product_info.get("precio final (redondeado)", "N/A")
            price_original = product_info.get("precio original", "N/A")
            stock = product_info.get("stock disponible", "0")
            desc = product_info.get("descripción", "")

            return (
                f"¡Hola! Veo que estás consultando sobre el **{prod_name}** de la marca **{category}**.\n\n"
                f"Este dispositivo está disponible con un precio especial de Innova Center de **{price_final}** (precio original de lista: {price_original}). "
                f"Actualmente contamos con **{stock}** unidades en stock físico listo para entrega inmediata.\n\n"
                f"Detalles del equipo: {desc or 'Garantía oficial de 1 año.'}\n\n"
                f"¿Deseas que te reservemos uno para retirarlo en nuestra tienda de Orinokia Mall o tienes alguna duda adicional?\n\n"
                f"*(Nota técnica: El Asesor de IA está operando en Modo Simulado de contingencia ya que no se ha configurado una API Key de Groq en `backend/.env`)*"
            )

        # Buscar en el catálogo local si pregunta por un producto
        if "precio" in user_lower or "cuesta" in user_lower or "cuánto" in user_lower or "disponible" in user_lower or "inventario" in user_lower or "tiene" in user_lower:
            lines = [line.strip() for line in catalog_context.strip().split("\n") if line.strip() and line.startswith("-")]
            matched_lines = []
            for line in lines:
                words = [w for w in user_lower.split() if len(w) > 3]
                if any(w in line.lower() for w in words):
                    matched_lines.append(line)
            
            if matched_lines:
                results_str = "\n".join(matched_lines)
                return (
                    f"¡Hola! Busqué en nuestro inventario de Innova Center y encontré la siguiente información:\n\n"
                    f"{results_str}\n\n"
                    f"Recuerda que a los precios de lista les aplicamos el redondeo del 0.50 superior al facturar. "
                    f"¿Te interesa alguno en particular?\n\n"
                    f"*(Nota técnica: El Asesor de IA está operando en Modo Simulado de contingencia ya que no se ha configurado una API Key de Groq en `backend/.env`)*"
                )
                
        # Respuesta general de bienvenida
        return (
            "¡Hola! Bienvenido al Chatbot de **Innova Center** en Orinokia Mall. "
            "Soy tu asistente virtual y puedo ayudarte con detalles del catálogo, consultas de stock, precios y garantías.\n\n"
            "Por favor escanea el código QR de cualquier producto o visita la sección de Catálogo para ver lo que tenemos disponible. "
            "Si tienes dudas sobre las garantías de la tienda o métodos de pago, puedes preguntarme con total libertad.\n\n"
            "*(Nota de desarrollo: Por favor configura tu `GROQ_API_KEY` en el archivo `backend/.env` para activar las respuestas completas impulsadas por Inteligencia Artificial)*"
        )

    @staticmethod
    def format_product_context(product: Product) -> str:
        if not product:
            return "No hay un producto específico seleccionado en este momento."
        
        rounded_price = ProductService.apply_rounding(product.price)
        model_info = f"\n        Modelo: {product.model}" if product.model and product.product_type == 'linea blanca' else (f"\n        Modelo: {product.model}" if product.model else "")
        return f"""
        Producto: {product.name}{model_info}
        Categoría: {product.category}
        Descripción: {product.description}
        Precio Base en Divisas (USD): ${product.price}
        Stock disponible: {product.stock}
        Garantía: 1 año directamente en Innova Center.
        """
