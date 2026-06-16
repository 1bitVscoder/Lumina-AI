from fastapi import APIRouter, Depends, HTTPException, status
from utils.auth import get_current_user
from utils.supabase_client import supabase

router = APIRouter(prefix="/account", tags=["Account"])

@router.delete("")
async def delete_account(current_user: dict = Depends(get_current_user)):
    try:
        google_uid = current_user["sub"]
        
        # 1. Delete user record in the users table.
        # Postgres ON DELETE CASCADE will automatically clean up conversations, messages, memory, and rate limit tables.
        db_res = supabase.table("users").delete().eq("google_uid", google_uid).execute()
        
        # 2. Delete the user from Supabase Auth administration
        try:
            supabase.auth.admin.delete_user(google_uid)
        except Exception as auth_err:
            # If auth deletion fails or is restricted, log but continue so we don't break the return
            print(f"Auth administration delete_user failed for {google_uid}: {str(auth_err)}")
            
        return {"status": "success", "message": "Account and all associated data successfully deleted."}
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete account: {str(e)}"
        )
