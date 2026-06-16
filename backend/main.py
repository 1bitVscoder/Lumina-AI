import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

from routes import health, onboarding, session, chat, account

app = FastAPI(
    title="Lumina Backend",
    version="1.0.0"
)

# Configure CORS
allowed_origins_str = os.getenv("ALLOWED_ORIGINS", "*")
allowed_origins = [origin.strip() for origin in allowed_origins_str.split(",")]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(health.router)
app.include_router(onboarding.router)
app.include_router(session.router)
app.include_router(chat.router)
app.include_router(account.router)

@app.get("/")
async def root():
    return {"message": "Welcome to Lumina AI Companion API"}
