import os
from supabase import create_client, Client

SUPABASE_URL = os.getenv("SUPABASE_URL", "").rstrip(".")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY", "")

if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
    raise ValueError("Missing SUPABASE_URL or SUPABASE_SERVICE_KEY in environment variables")

# Service role client has bypass RLS privileges for backend admin work
supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
