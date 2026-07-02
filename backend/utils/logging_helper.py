import logging

def get_logger(name: str = __name__) -> logging.Logger:
    """Return a module‑level logger configured for the project.
    Centralising logger creation makes it easy to adjust format or level in one place.
    """
    logger = logging.getLogger(name)
    if not logger.handlers:
        # Basic configuration if no handlers attached
        logging.basicConfig(
            level=logging.INFO,
            format="[%(asctime)s] %(levelname)s in %(module)s: %(message)s",
        )
    return logger
