# db.py
import os
import psycopg2

from dotenv import load_dotenv

load_dotenv()


def get_connection():

    database_url = os.getenv(
        "DATABASE_URL"
    )

    if database_url:

        return psycopg2.connect(
            database_url,
            connect_timeout=5
        )

    return psycopg2.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT"),
        database=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        connect_timeout=5
    )

## Check database can connect Coomand: python backend/db.py
if __name__ == "__main__":
    try:
        connection = get_connection()
        print("Database connected successfully!")
        connection.close()
    except Exception as error:
        print("Database connection failed:")
        print(error)