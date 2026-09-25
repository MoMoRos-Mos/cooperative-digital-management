from fastapi import FastAPI, APIRouter
from psycopg2.extras import RealDictCursor

from backend.db import get_connection

router = APIRouter(
    prefix="/dashboard",
    tags=["Dashboard"]
)

## Get dashboard summary
@router.get("/summary")
def get_dashboard_summary():

    connection = get_connection()

    cursor = connection.cursor(
        cursor_factory=RealDictCursor
    )

    cursor.execute ("""
        WITH member_summary AS (
            SELECT
                COUNT(*) AS total_member,
                COUNT(*) FILTER(
                    WHERE status = 'ACTIVE'
                ) AS active_members,
                COUNT(*) FILTER(
                    WHERE status = 'INACTIVE'
                ) AS inactive_members
            FROM members
        ),

        deposit_summary AS (
            SELECT
                COALESCE(SUM(balance), 0) AS total_deposit
            FROM deposit_accounts
        ),

        loan_summary AS (
            SELECT
                COALESCE(SUM(principal), 0) AS total_loan_principal
            FROM loans
        ),
        
        payment_summary AS (
            SELECT
                COALESCE(SUM(principal_paid), 0) AS total_principal_paid
            FROM payments
        )

            SELECT
                ms.total_member,
                ms.active_members,
                ms.inactive_members,
                ds.total_deposit,
                ls.total_loan_principal,
                ps.total_principal_paid,
                ls.total_loan_principal - ps.total_principal_paid AS outstanding_principal

            FROM member_summary ms
            CROSS JOIN deposit_summary ds
            CROSS JOIN loan_summary ls
            CROSS JOIN payment_summary ps;

    """)

    summary = cursor.fetchone()

    cursor.close()
    connection.close()

    return summary