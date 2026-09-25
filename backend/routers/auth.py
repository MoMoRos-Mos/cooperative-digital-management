from sys import prefix
import token

from psycopg2.extensions import cursor
from fastapi import (
    APIRouter,
    HTTPException,
    status
)

from psycopg2.extras import RealDictCursor

from backend.db import get_connection
from backend.schemas import (
    LoginRequest,
    TokenResponse
)
from backend.security import (
    verify_password,
    create_access_token
)

router = APIRouter(
    prefix="/auth",
    tags=["Auth"]
)

## Create login API
@router.post(
    "/login",
    response_model=TokenResponse
)
def login(
    login_date: LoginRequest
):

    connection = get_connection()

    cursor = connection.cursor(
        cursor_factory=RealDictCursor
    )

    try:

            cursor.execute("""
            SELECT 
                user_id,
                username,
                password_hash,
                role,
                status
            FROM users
            WHERE username = %s;
            """,
                (
                    login_date.username,
                )
            )

            user = cursor.fetchone()

            if not user:

                raise HTTPException(
                    status_code=
                        status.HTTP_401_UNAUTHORIZED,
                    detail=
                        "Invalid username or password"
                )

            if user["status"] != "ACTIVE":

                raise HTTPException(
                    status_code=
                        status.HTTP_403_FORBIDDEN,
                    detail=
                        "User account is inactive"
                )

            password_ok = verify_password(
                login_date.password,
                user["password_hash"]
            )

            if not password_ok:
                
                raise HTTPException(
                    status_code=
                        status.HTTP_401_UNAUTHORIZED,
                    detail=
                        "Invalid username or password"
                )

            token = create_access_token(
                    user_id=user["user_id"],
                    username=user["username"],
                    role=user["role"]
             )

            return {
                    "access_token": token,
                    "token_type": "bearer",
                    "role": user["role"],
                    "username": user["username"],
                    "status": user["status"]
                }

    finally:
        cursor.close()
        connection.close()