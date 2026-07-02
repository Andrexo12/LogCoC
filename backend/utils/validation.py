def is_valid_key(key: str | None) -> bool:
    """Validate that an API key looks like a real key and not a placeholder.
    Common placeholder strings are filtered out.
    """
    if not key:
        return False
    placeholder_terms = ["tu_groq_key", "aqui", "placeholder", "your_api_key"]
    key_lower = key.strip().lower()
    return not any(term in key_lower for term in placeholder_terms)
