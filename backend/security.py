import token
from pwdlib import PasswordHash

import os 

from datetime import datetime, timedelta, timezone

import jwt


password_hash = PasswordHash.recommended()


def hash_password(password: str) -> str:
    return password_hash.hash(password)


def verify_password(
    plain_password: str,
    hashed_password: str
) -> bool:

    return password_hash.verify(
        plain_password,
        hashed_password
    )

JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY")
JWT_ALGORITHM = os.getenv(
    "JWT_ALGORITHM",
    "HS256"
)

JWT_EXPIRE_MINUTES = int(
    os.getenv(
        "JWT_EXPIRE_MINUTES",
        "60"
    )
)

def create_access_token(
    user_id: int,
    username: str,
    role: str
) -> str:

    expire = (
        datetime.now(timezone.utc)
        + timedelta(
            minutes=JWT_EXPIRE_MINUTES
        )
    )

    paylaod = {
        "sub": str(user_id),
        "username": username,
        "role": role,
        "exp": expire
    }

    token = jwt.encode(
        paylaod,
        JWT_SECRET_KEY,
        algorithm = JWT_ALGORITHM
    )

    return token
    
def decode_access_token(
    token: str
) -> dict:
    
    payload = jwt.decode(
        token,
        JWT_SECRET_KEY,
        algorithms=[
            JWT_ALGORITHM
        ]
    )
    
    return payload