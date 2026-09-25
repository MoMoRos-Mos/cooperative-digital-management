from fastapi import APIRouter, HTTPException
from psycopg2.extras import RealDictCursor
from psycopg2 import IntegrityError

from backend.db import get_connection
from backend.schemas import MemberCreate, MemberUpdate

router = APIRouter(
    prefix="/members",
    tags=["Members"]
)

## Get all members
@router.get("")
def get_members():
    connection = get_connection()
    cursor = connection.cursor(
        cursor_factory = RealDictCursor
    )

    cursor.execute("""
        SELECT
            member_id,
            member_no,
            full_name,
            department,
            join_date,
            status
        FROM members
        ORDER BY member_id;
    """)

    rows = cursor.fetchall()

    cursor.close()
    connection.close()

    return rows

@router.get("/{member_id}")
def get_member(member_id: int):
    connection = get_connection()

    cursor = connection.cursor(
        cursor_factory = RealDictCursor
    )

    cursor.execute("""
        SELECT
            member_id,
            member_no,
            full_name,
            department,
            join_date,
            status
        FROM members
        WHERE member_id = %s;

    """,(member_id,))

    member = cursor.fetchone()

    cursor.close()
    connection.close()

    if member is None:
        raise HTTPException(
            status_code = 404,
            detail = "Member not found"
        )
    return member

## POST /members
@router.post("", status_code=201)
def create_member(member: MemberCreate):
    
    connection = get_connection()

    cursor = connection.cursor(
        cursor_factory=RealDictCursor
    )

    try:
        cursor.execute("""
            INSERT INTO members
            (
                member_no,
                full_name,
                department,
                join_date,
                status
            )
            VALUES
            (%s, %s, %s, %s, %s)
            RETURNING
                member_id,
                member_no,
                full_name,
                department,
                join_date,
                status;
        """, (
            member.member_no,
            member.full_name,
            member.department,
            member.join_date,
            member.status
        ))

        new_member = cursor.fetchone()

        connection.commit()

        return new_member

    except IntegrityError:
        connection.rollback()

        raise HTTPException(
            status_code=409,
            detail="Member number already exists"
        )

    finally:
        cursor.close()
        connection.close()


## PUT /members/{id}
@router.put("/{member_id}")
def update_member(
    member_id: int,
    member: MemberUpdate
):
    connection = get_connection()

    cursor = connection.cursor(
        cursor_factory=RealDictCursor
    )

    cursor.execute("""
        UPDATE members
        SET
            full_name = %s,
            department = %s,
            join_date = %s,
            status = %s
        WHERE member_id = %s
        RETURNING
            member_id,
            member_no,
            full_name,
            department,
            join_date,
            status;
    """, (
            member.full_name,
            member.department,
            member.join_date,
            member.status,
            member_id
        ))

    updated_member = cursor.fetchone()

    if updated_member is None:
        connection.rollback()

        cursor.close()
        connection.close()

        raise HTTPException(
            status_code=404,
            detail="Member not found"
        )

    connection.commit()

    cursor.close()
    connection.close()

    return updated_member


## DELETE
@router.delete("/{member_id}")
def deactivate_member(member_id: int):
    connection = get_connection()

    cursor = connection.cursor(
        cursor_factory=RealDictCursor
    )

    cursor.execute("""
        UPDATE members
        SET status = 'INACTIVE'
        WHERE member_id = %s
        RETURNING
            member_id,
            member_no,
            full_name,
            department,
            join_date,
            status;
    """, (member_id,))
    
    member = cursor.fetchone()

    if member is None:
        connection.rollback()

        cursor.close()
        connection.close()

        raise HTTPException(
            status_code=404,
            detail="Member not found"
        )    
    
    connection.commit()

    cursor.close()
    connection.close()

    return {
        "message": "Member deactivated",
        "member": member
    }
    
    