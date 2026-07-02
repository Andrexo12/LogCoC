import os
import uuid
import logging
from typing import Optional

logger = logging.getLogger(__name__)

def save_local_image(file_bytes: bytes, filename: str) -> str:
    """Save an uploaded file to the static/uploads directory and return its relative URL.
    Creates the directory if needed.
    """
    upload_dir = os.path.join(os.getcwd(), "static", "uploads")
    os.makedirs(upload_dir, exist_ok=True)
    ext = filename.split('.')[-1].lower() if '.' in filename else 'png'
    if ext not in ["jpg", "jpeg", "png", "webp", "gif"]:
        ext = "png"
    unique_filename = f"{uuid.uuid4().hex}.{ext}"
    file_path = os.path.join(upload_dir, unique_filename)
    try:
        with open(file_path, "wb") as f:
            f.write(file_bytes)
    except Exception as e:
        logger.error(f"Failed to write image file {file_path}: {e}")
        raise
    return f"/static/uploads/{unique_filename}"
