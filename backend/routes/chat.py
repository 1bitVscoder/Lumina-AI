from fastapi import APIRouter, Depends, HTTPException, status
from models.request_models import ChatRequest
from utils.auth import get_current_user
from utils.supabase_client import supabase
from services.tone_classifier import classify_tone
from services.prompt_builder import build_system_prompt
from services.memory_service import get_user_memory
from services.llm_service import generate_gemini_content

from services.rate_limiter import check_rate_limit

router = APIRouter(prefix="/chat", tags=["Chat"])

@router.post("")
async def chat(
    request: ChatRequest,
    current_user: dict = Depends(get_current_user)
):
    # 1. Security check: verify request user matches JWT sub
    if request.user_id != current_user["sub"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: Cannot perform chat operations for another user"
        )
        
    try:
        # 2. Get database user UUID from users table (google_uid matches current_user['sub'])
        user_res = supabase.table("users")\
            .select("id, ai_name, archetype")\
            .eq("google_uid", request.user_id)\
            .maybe_single()\
            .execute()
            
        if not user_res.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User profile not found. Please complete onboarding first."
            )
            
        db_user_id = user_res.data["id"]
        ai_name = user_res.data.get("ai_name", "Lumina")
        archetype = user_res.data.get("archetype", "drifter")
        
        # 2.5 Daily Rate Limiting check
        await check_rate_limit(db_user_id)
        
        # 3. Create conversation if not provided
        conversation_id = request.conversation_id
        if not conversation_id:
            conv_res = supabase.table("conversations").insert({
                "user_id": db_user_id
            }).execute()
            if not conv_res.data:
                raise Exception("Failed to initialize conversation in database")
            conversation_id = conv_res.data[0]["id"]
            
        # 4. Classify tone and set generation temperature dynamically
        detected_tone, temperature = classify_tone(request.message)
        
        # 5. Fetch long-term memories and latest session summary
        long_term_facts, short_term_summary = await get_user_memory(db_user_id)
        
        # 6. Build the dynamic system prompt
        system_prompt = build_system_prompt(
            ai_name=ai_name,
            archetype=archetype,
            long_term_memories=long_term_facts,
            short_term_summary=short_term_summary,
            detected_tone=detected_tone,
            temperature=temperature
        )
        
        # 7. Clip history to last 10 turns (5 user, 5 assistant) to optimize token windows
        clipped_history = request.history[-10:] if request.history else []
        
        # 8. Call Gemini content generation with automated key-rotation fallback
        reply, key_used = await generate_gemini_content(
            system_instruction=system_prompt,
            history=clipped_history,
            user_message=request.message,
            image_base64=request.image_base64,
            temperature=temperature
        )
        
        # 9. Save user message and assistant reply to Supabase database
        # Save user message
        supabase.table("messages").insert({
            "conversation_id": conversation_id,
            "user_id": db_user_id,
            "role": "user",
            "content": request.message,
            "image_url": request.image_base64
        }).execute()
        
        # Save assistant message
        supabase.table("messages").insert({
            "conversation_id": conversation_id,
            "user_id": db_user_id,
            "role": "assistant",
            "content": reply
        }).execute()
        
        # 10. Increment conversation turn count in database
        supabase.rpc("increment_conversation_turn", {
            "conv_id": conversation_id
        }).execute()
        
        return {
            "reply": reply,
            "conversation_id": conversation_id,
            "temperature_used": temperature,
            "tokens_used": 0 # Gemini response doesn't explicitly expose exact token consumption easily in REST
        }
        
    except HTTPException as e:
        raise e
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Chat generation failed: {str(e)}"
        )
