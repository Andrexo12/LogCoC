# Dockerfile para FastAPI
FROM python:3.11-slim

WORKDIR /app

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    gcc \
    default-libmysqlclient-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Copiamos el archivo desde la raíz del proyecto (contexto de build)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiamos el contenido del backend
COPY backend/ .

# Exponer el puerto de FastAPI
EXPOSE 8000

CMD ["uvicorn app.main:app", "--host", "0.0.0.0", "--port", "8000"]
