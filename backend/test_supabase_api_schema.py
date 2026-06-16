import os
from dotenv import load_dotenv
from supabase import create_client
from supabase.lib.client_options import SyncClientOptions

load_dotenv()
url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_SERVICE_KEY")
schema = os.getenv("SUPABASE_DB_SCHEMA", "public")
print(f"Connecting with SyncClientOptions schema='{schema}'...")
options = SyncClientOptions(schema=schema)
supabase = create_client(url, key, options=options)
try:
    res = supabase.table("users").select("*").limit(1).execute()
    print("Success:", res)
except Exception as e:
    import traceback
    traceback.print_exc()
