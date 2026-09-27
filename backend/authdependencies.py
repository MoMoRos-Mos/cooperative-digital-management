import token

from psycopg2.extensions import cursor
import jwt

from fastapi import HTTPException, Depends, status

from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from psycopg2.extras import RealDictCursor

from backend.db import get_connection

from backend.security import decode_access_token

bearer_scheme = HTTPBearer(auto_error=False)


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
):

    if credentials is None:

        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = credentials.credentials

    try:

        payload = decode_access_token(token)

    except jwt.InvalidTokenError:

        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user_id = payload.get("sub")

    if user_id is None:

        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token payload"
        )

    connection = get_connection()

    cursor = connection.cursor(cursor_factory=RealDictCursor)

    try:

        cursor.execute(
            """
            SELECT
                user_id,
                username,
                role,
                status
            FROM users
            WHERE user_id = %s
        """,
            (int(user_id),),
        )

        user = cursor.fetchone()

    finally:
        cursor.close()
        connection.close()

    if not user:

        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found"
        )

    if user["status"] != "ACTIVE":

        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="User account is inactive"
        )

    return user


def require_admin(current_user=Depends(get_current_user)):

    if current_user["role"] != "ADMIN":

        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Admin permission required"
        )

    return current_user
