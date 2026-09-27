from getpass import getpass

from backend.db import get_connection
from backend.security import hash_password

username = input(
    "User name: "
).strip()

password = input(
    "User Password: "
)

hashed_password = hash_password(
    password
)

connection = get_connection()
cursor = connection.cursor()

try:

    cursor.execute("""
        INSERT INTO users (
            username,
            password_hash,
            role,
            status
        )
        VALUES(
            %s,
            %s,
            'USER',
            'ACTIVE'
        )
        RETURNING(
            user_id,
            username,
            role,
            status
        )
        """,
        (
            username,
            hashed_password
        )
    )

    user = cursor.fetchone()

    connection.commit()

    print(
        "User created:",
        user
    )

except Exception as error:

    connection.rollback()

    print(
        "Cannot create user:",
        error
    )

finally:
    cursor.close()
    connection.close()