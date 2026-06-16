from pydantic import BaseModel, Field
from typing import List, Optional

class OnboardingRequest(BaseModel):
  user_id: str = Field(..., description="The UUID of the user from Supabase auth")
  answers: List[str] = Field(default=[], description="List of responses from onboarding personality quiz")

class ChatRequest(BaseModel):
  user_id: str
  conversation_id: Optional[str] = None
  message: str = Field(..., max_length=1000)
  image_base64: Optional[str] = None
  history: List[dict] = []
