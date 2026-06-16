from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from typing import List, Optional
from utils.auth import get_current_user
from utils.supabase_client import supabase
from services.memory_service import get_user_memory, save_user_memory
from services.llm_service import generate_summary

router = APIRouter(prefix="/session", tags=["Session"])

class StartSessionRequest(BaseModel):
    user_id: str

class EndSessionRequest(BaseModel):
    user_id: str
    conversation_id: str
    full_history: List[dict] # Turn list containing 'role' and 'content' keys

@router.post("/start-session")
async def start_session(
    request: StartSessionRequest,
    current_user: dict = Depends(get_current_user)
):
    if request.user_id != current_user["sub"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: Cannot start session for another user"
        )
        
    try:
        # Retrieve user profile configuration
        user_response = supabase.table("users")\
            .select("id, ai_name, archetype")\
            .eq("google_uid", request.user_id)\
            .maybe_single()\
            .execute()
            
        ai_name = "Lumina"
        archetype = "drifter"
        db_user_id = None
        
        if user_response and user_response.data:
            ai_name = user_response.data.get("ai_name", "Lumina")
            archetype = user_response.data.get("archetype", "drifter")
            db_user_id = user_response.data.get("id")

        # Retrieve memory logs
        long_term_facts, short_term_summary = await get_user_memory(db_user_id)
        
        return {
            "ai_name": ai_name,
            "archetype": archetype,
            "long_term_memory": long_term_facts,
            "short_term_summary": short_term_summary
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch session setup: {str(e)}"
        )

@router.post("/end-session")
async def end_session(
    request: EndSessionRequest,
    current_user: dict = Depends(get_current_user)
):
    if request.user_id != current_user["sub"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: Cannot end session for another user"
        )
        
    if not request.full_history:
        return {"status": "skipped", "message": "History was empty; summary skipped."}

    try:
        # Retrieve database UUID for the user
        user_res = supabase.table("users")\
            .select("id")\
            .eq("google_uid", request.user_id)\
            .maybe_single()\
            .execute()
        db_user_id = user_res.data.get("id") if user_res and user_res.data else None

        # Generate summary of chat using Gemini
        summary_text = await generate_summary(request.full_history)
        
        # Save summary in user memory table (short-term history track)
        await save_user_memory(db_user_id, "short_term", summary_text)
        
        # Save summary inside conversations history row
        supabase.table("conversations").update({
            "summary": summary_text
        }).eq("id", request.conversation_id).execute()
        
        return {"status": "memory_saved"}
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to save session memory: {str(e)}"
        )
