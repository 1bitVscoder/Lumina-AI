import os
import json
from datetime import datetime, timedelta
from typing import List, Dict, Optional

class KeyRotator:
    def __init__(self):
        self.fallback_key: Optional[str] = os.getenv("GEMINI_API_KEY")
        self.keys: List[Dict] = []
        self.index = 0
        
        # Load rotation keys if present
        keys_json = os.getenv("API_KEYS_JSON")
        if keys_json:
            try:
                parsed_keys = json.loads(keys_json)
                if isinstance(parsed_keys, list):
                    for k in parsed_keys:
                        if isinstance(k, str):
                            self.keys.append({
                                "value": k,
                                "on_cooldown": False,
                                "cooldown_until": None
                            })
            except Exception:
                # If JSON parsing fails, fall back to empty list (will use fallback_key)
                pass

    def get_active_key(self) -> str:
        now = datetime.utcnow()
        
        # 1. Search through rotation keys
        if self.keys:
            for _ in range(len(self.keys)):
                key = self.keys[self.index % len(self.keys)]
                self.index += 1
                
                # Check if key is available
                if not key["on_cooldown"]:
                    return key["value"]
                
                # Check if cooldown expired
                if key["cooldown_until"] and key["cooldown_until"] < now:
                    key["on_cooldown"] = False
                    key["cooldown_until"] = None
                    return key["value"]
        
        # 2. Fall back to the main API key if rotation keys are empty or all are on cooldown
        if self.fallback_key:
            return self.fallback_key
            
        raise Exception("All rotation keys are on cooldown and no GEMINI_API_KEY fallback is configured.")

    def mark_cooldown(self, key_value: str, duration_minutes: int = 10):
        now = datetime.utcnow()
        for key in self.keys:
            if key["value"] == key_value:
                key["on_cooldown"] = True
                key["cooldown_until"] = now + timedelta(minutes=duration_minutes)
                break

# Singleton instance for the backend application
key_rotator = KeyRotator()
