def classify_tone(message: str) -> tuple[str, float]:
    """
    Heuristically classifies the tone of the user message and returns a tuple
    of (tone_label, generation_temperature).
    Saves API tokens by avoiding an LLM call for tone detection.
    """
    lowered = message.lower()
    
    # Empathetic tone triggers
    if any(w in lowered for w in ["stressed", "tired", "sad", "anxious", "overwhelmed", "rough", "bad day", "hurt", "crying"]):
        return ("empathetic", 0.55)
        
    # Playful/banter tone triggers
    if any(w in lowered for w in ["haha", "lol", "lmao", "bruh", "bro", "😂", "joke", "funny", "lmfao"]):
        return ("playful", 0.95)
        
    # Analytical/logical tone triggers
    if any(w in lowered for w in ["why", "how", "explain", "think", "opinion", "what if", "analyze", "solve"]):
        return ("analytical", 0.65)
        
    # Reflective/philosophical tone triggers
    if any(w in lowered for w in ["feel", "life", "meaning", "soul", "deep", "wonder", "existential", "purpose"]):
        return ("reflective", 0.80)
        
    # Default neutral tone settings
    return ("neutral", 0.75)
