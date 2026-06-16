from fastapi import APIRouter, Depends, HTTPException, status
from models.request_models import OnboardingRequest
from utils.auth import get_current_user
from utils.supabase_client import supabase

router = APIRouter(prefix="/onboarding", tags=["Onboarding"])

def calculate_archetype(answers: list[str]) -> str:
    scores = {"venter": 0, "analyst": 0, "jester": 0, "seeker": 0, "drifter": 0}
    for ans in answers:
        a = ans.lower()
        # Venter mappings
        if any(w in a for w in ["vent", "heard", "soft", "gentle"]):
            scores["venter"] += 1
        # Analyst mappings
        if any(w in a for w in ["advice", "honest", "logical", "analyst"]):
            scores["analyst"] += 1
        # Jester mappings
        if any(w in a for w in ["joke", "hangout", "funny", "distraction", "hype", "chaotic", "jester"]):
            scores["jester"] += 1
        # Seeker mappings
        if any(w in a for w in ["quiet", "deep", "silence", "seeker"]):
            scores["seeker"] += 1
        # Drifter mappings
        if any(w in a for w in ["netflix", "spontaneous", "mix", "chill", "drifter"]):
            scores["drifter"] += 1

    # Return key with the maximum score
    return max(scores, key=scores.get)

@router.post("")
async def submit_onboarding(
    request: OnboardingRequest,
    current_user: dict = Depends(get_current_user)
):
    # Security: Verify that the requesting user matches the JWT sub
    if request.user_id != current_user["sub"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: You cannot perform onboarding for another user"
        )

    # Compute archetype from answer list (if empty, assign default "drifter")
    if not request.answers:
        archetype = "drifter"
    else:
        archetype = calculate_archetype(request.answers)

    try:
        # Update users table via admin client
        # In Supabase auth, sub is the google_uid/id mapped to auth.users.id.
        # We search by google_uid or id. Let's look up by google_uid = current_user["sub"]
        response = supabase.table("users").update({
            "archetype": archetype,
            "onboarded": True
        }).eq("google_uid", current_user["sub"]).execute()

        # If user row was not found (maybe they haven't been inserted on auth yet)
        # We can upsert the record using email from the JWT
        if not response.data:
            email = current_user.get("email", "")
            if not email:
                email = f"guest_{current_user['sub']}@lumina.ai"
            name = current_user.get("user_metadata", {}).get("full_name", "Guest")
            avatar = current_user.get("user_metadata", {}).get("avatar_url", "")
            
            response = supabase.table("users").upsert({
                "google_uid": current_user["sub"],
                "email": email,
                "display_name": name,
                "avatar_url": avatar,
                "archetype": archetype,
                "onboarded": True
            }).execute()

        return {"archetype": archetype}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Database update failed: {str(e)}"
        )
