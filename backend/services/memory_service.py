from typing import List, Optional
from utils.supabase_client import supabase

async def get_user_memory(user_id: str) -> tuple[List[str], Optional[str]]:
    """
    Fetches the long term memory facts and the latest short term session summary
    for a user from Supabase.
    Returns:
        tuple[long_term_facts_list, short_term_summary_string]
    """
    long_term_facts: List[str] = []
    short_term_summary: Optional[str] = None
    
    try:
        # 1. Fetch long-term facts
        lt_response = supabase.table("user_memory")\
            .select("content")\
            .eq("user_id", user_id)\
            .eq("memory_type", "long_term")\
            .execute()
            
        if lt_response.data:
            long_term_facts = [row["content"] for row in lt_response.data]
            
        # 2. Fetch latest short-term session summary
        st_response = supabase.table("user_memory")\
            .select("content")\
            .eq("user_id", user_id)\
            .eq("memory_type", "short_term")\
            .order("created_at", desc=True)\
            .limit(1)\
            .execute()
            
        if st_response.data:
            short_term_summary = st_response.data[0]["content"]
            
    except Exception as e:
        # If DB query fails, we gracefully return empty memory sets so conversation can continue
        print(f"Error querying memory tables for user {user_id}: {str(e)}")
        
    return long_term_facts, short_term_summary

async def save_user_memory(user_id: str, memory_type: str, content: str) -> None:
    """
    Saves a memory block (short_term summary or long_term fact) to Supabase.
    """
    try:
        supabase.table("user_memory").insert({
            "user_id": user_id,
            "memory_type": memory_type,
            "content": content
        }).execute()
    except Exception as e:
        print(f"Failed to save {memory_type} memory for user {user_id}: {str(e)}")
