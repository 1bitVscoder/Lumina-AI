import os
import jwt
import httpx
from jwt import PyJWK
from fastapi import Header, HTTPException, status

SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_JWT_SECRET = os.getenv("SUPABASE_JWT_SECRET")

# Cache for the JWKS public key
_jwks_key_cache: PyJWK | None = None

def _get_jwks_key() -> PyJWK | None:
    """Fetch and cache the ES256 public key from Supabase JWKS endpoint."""
    global _jwks_key_cache
    if _jwks_key_cache is not None:
        return _jwks_key_cache

    jwks_url = f"{SUPABASE_URL.rstrip('/')}/auth/v1/.well-known/jwks.json"
    try:
        resp = httpx.get(jwks_url, timeout=5)
        resp.raise_for_status()
        jwks_data = resp.json()
        keys = jwks_data.get("keys", [])
        if keys:
            _jwks_key_cache = PyJWK(keys[0])
            print(f"JWKS: Loaded ES256 public key (kid={keys[0].get('kid', 'unknown')})")
            return _jwks_key_cache
    except Exception as e:
        print(f"JWKS: Failed to fetch public key from {jwks_url}: {e}")
    return None

def validate_jwt(token: str) -> dict:
    if not SUPABASE_JWT_SECRET and not SUPABASE_URL:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Neither SUPABASE_JWT_SECRET nor SUPABASE_URL is configured"
        )

    # Detect token algorithm
    try:
        unverified_header = jwt.get_unverified_header(token)
        token_alg = unverified_header.get("alg", "HS256")
    except Exception:
        token_alg = "HS256"

    # Try ES256 verification via JWKS if token uses it
    if token_alg == "ES256":
        jwks_key = _get_jwks_key()
        if jwks_key is not None:
            try:
                payload = jwt.decode(
                    token,
                    jwks_key.key,
                    algorithms=["ES256"],
                    options={"verify_aud": True},
                    audience="authenticated"
                )
                return payload
            except jwt.ExpiredSignatureError as e:
                print(f"JWT Verification Failed (Expired, ES256): {e}")
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Token expired"
                )
            except jwt.InvalidTokenError as e:
                print(f"JWT Verification Failed (Invalid, ES256): {e}")
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail=f"Invalid token: {e}"
                )

    # Fall back to HS256 with symmetric secret
    if not SUPABASE_JWT_SECRET:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token uses unsupported algorithm and no JWT secret configured"
        )

    try:
        payload = jwt.decode(
            token,
            SUPABASE_JWT_SECRET,
            algorithms=["HS256"],
            options={"verify_aud": True},
            audience="authenticated"
        )
        return payload
    except jwt.ExpiredSignatureError as e:
        print(f"JWT Verification Failed (Expired): {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token expired"
        )
    except jwt.InvalidTokenError as e:
        print(f"JWT Verification Failed (Invalid): {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token: {e}"
        )

async def get_current_user(authorization: str = Header(...)) -> dict:
    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Authorization header format. Must start with 'Bearer '"
        )
    token = authorization.split(" ")[1]
    return validate_jwt(token)
