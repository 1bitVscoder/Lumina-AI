from datetime import datetime, timedelta, timezone
from fastapi import HTTPException, status
from utils.supabase_client import supabase

async def check_rate_limit(db_user_id: str) -> None:
    """
    Validates the user's daily rate limit (50 messages per day, resetting at UTC midnight).
    Increments count on success, raises HTTP 429 on failure.
    """
    now_utc = datetime.now(timezone.utc)
    
    # Calculate next UTC midnight reset time
    tomorrow_date = now_utc.date() + timedelta(days=1)
    next_reset = datetime(
        tomorrow_date.year, 
        tomorrow_date.month, 
        tomorrow_date.day, 
        tzinfo=timezone.utc
    )

    try:
        # Fetch current rate limit details
        response = supabase.table("user_rate_limit")\
            .select("*")\
            .eq("user_id", db_user_id)\
            .maybe_single()\
            .execute()
            
        # 1. No record exists yet -> Insert first turn
        if not response or not response.data:
            supabase.table("user_rate_limit").insert({
                "user_id": db_user_id,
                "message_count": 1,
                "reset_at": next_reset.isoformat()
            }).execute()
            return

        data = response.data
        reset_at_db = datetime.fromisoformat(data["reset_at"].replace("Z", "+00:00"))
        
        # 2. Reset window has passed -> Reset counter to 1 and update reset time
        if reset_at_db < now_utc:
            supabase.table("user_rate_limit").update({
                "message_count": 1,
                "reset_at": next_reset.isoformat()
            }).eq("user_id", db_user_id).execute()
            return
            
        # 3. Limit exceeded -> Raise HTTP 429 Too Many Requests
        if data["message_count"] >= 50:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail={
                    "error": "rate_limit_exceeded",
                    "reset_at": data["reset_at"]
                }
            )

        # 4. Under limit -> Increment turn count
        supabase.table("user_rate_limit").update({
            "message_count": data["message_count"] + 1
        }).eq("user_id", db_user_id).execute()
        
    except HTTPException as e:
        # Re-raise explicit rate limit exceptions
        raise e
    except Exception as e:
        # Fail open or log error? Standard practice is to fail open on database rate-limit errors
        # to ensure user is not blocked due to DB connection issues, but log it.
        print(f"Error checking rate limit for user {db_user_id}: {str(e)}")
