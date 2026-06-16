import httpx
from typing import List, Dict, Optional
from services.key_rotator import key_rotator

async def generate_gemini_content(
    system_instruction: str,
    history: List[Dict[str, str]],
    user_message: str,
    image_base64: Optional[str] = None,
    temperature: float = 0.7
) -> tuple[str, str]:
    """
    Sends request to Gemini 1.5 Flash REST API with dynamic system instructions,
    multimodal inputs, temperature overrides, and automatic key rotation on failure.
    Returns:
        tuple[reply_text, api_key_used]
    """
    
    # 1. Format contents array for Gemini API (uses 'user' and 'model' roles)
    contents = []
    for turn in history:
        role = "user" if turn["role"] == "user" else "model"
        contents.append({
            "role": role,
            "parts": [{"text": turn["content"]}]
        })
        
    # Append the active user turn (including image if present)
    current_parts = []
    if image_base64:
        # Strip potential data:image/...;base64, headers
        clean_base64 = image_base64
        if "," in image_base64:
            clean_base64 = image_base64.split(",")[1]
            
        current_parts.append({
            "inlineData": {
                "mimeType": "image/jpeg",
                "data": clean_base64
            }
        })
        
    if user_message:
        current_parts.append({"text": user_message})
        
    contents.append({
        "role": "user",
        "parts": current_parts
    })
    
    # Payload base config
    payload = {
        "contents": contents,
        "systemInstruction": {
            "parts": [{"text": system_instruction}]
        },
        "generationConfig": {
            "temperature": temperature,
            "maxOutputTokens": 256  # keep response short and punchy
        }
    }
    
    max_retries = 3
    for attempt in range(max_retries):
        active_key = key_rotator.get_active_key()
        url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={active_key}"
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(url, json=payload, timeout=30.0)
                
                # If key is rate limited (429) or invalid (400/403)
                if response.status_code in [429, 400, 403]:
                    key_rotator.mark_cooldown(active_key)
                    # Retry using a different key
                    continue
                    
                response.raise_for_status()
                data = response.json()
                
                # Extract response text
                candidates = data.get("candidates", [])
                if not candidates:
                    raise Exception("Gemini API returned no text candidates.")
                    
                reply_text = candidates[0].get("content", {}).get("parts", [{}])[0].get("text", "")
                return reply_text.strip(), active_key
                
            except httpx.HTTPStatusError as e:
                # Mark key on cooldown and retry
                key_rotator.mark_cooldown(active_key)
                if attempt == max_retries - 1:
                    raise Exception(f"Gemini API returned error state: {str(e)}")
            except Exception as e:
                if attempt == max_retries - 1:
                    raise e
                    
    raise Exception("All rotation and fallback keys failed to respond successfully.")

async def generate_summary(history: List[Dict[str, str]]) -> str:
    """
    Sends conversational history to Gemini to retrieve a single sentence summary.
    Used for memory compression on session end.
    """
    system_instruction = (
        "You are an assistant that summarizes conversations in one concise sentence. "
        "Summarize the main topic discussed, the user's overall mood, and any major events mentioned. "
        "Write in third person (e.g., 'The user venting about project stresses and was tired')."
    )
    
    # Map turns
    contents = []
    for turn in history:
        role = "user" if turn["role"] == "user" else "model"
        contents.append({
            "role": role,
            "parts": [{"text": turn["content"]}]
        })
        
    contents.append({
        "role": "user",
        "parts": [{"text": "Summarize this entire chat history in one clear sentence."}]
    })
    
    payload = {
        "contents": contents,
        "systemInstruction": {
            "parts": [{"text": system_instruction}]
        },
        "generationConfig": {
            "temperature": 0.3, # low temperature for accurate summary
            "maxOutputTokens": 128
        }
    }
    
    # Fetch key and send request
    active_key = key_rotator.get_active_key()
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={active_key}"
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(url, json=payload, timeout=20.0)
            response.raise_for_status()
            data = response.json()
            reply_text = data["candidates"][0]["content"]["parts"][0]["text"]
            return reply_text.strip()
        except Exception as e:
            return f"Failed to generate summary: {str(e)}"
