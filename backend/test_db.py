import os
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()
url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_SERVICE_KEY")
print(f"Connecting to URL: {url}")
supabase = create_client(url, key)
try:
    res = supabase.table("users").select("*").limit(1).execute()
    print("Success:", res)
except Exception as e:
    import traceback
    print("Error occurred:")
    traceback.print_exc()
