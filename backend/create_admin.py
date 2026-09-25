from getpass import getpass

from backend.db import get_connection
from backend.security import hash_password

username = input("Admin username: ").strip()

password = getpass("Admin password: ")

hash_password = hash_password(password)

connection = get_connection()
cursor = connection.cursor()

try:

    cursor.execute(
        """
        INSERT INTO users (
            username,
            password_hash,
            role,
            status
        )
        VALUES (
            %s,
            %s,
            'ADMIN',
            'ACTIVE'
        )
        RETURNING user_id, username, role, status
        """,
        (username, hash_password),
    )

    admin = cursor.fetchone()

    connection.commit()

    print("Admin created:", admin)

except Exception as error:

    connection.close()

    print("Cannot create admin:", error)

finally:

    cursor.close()
    connection.close()
