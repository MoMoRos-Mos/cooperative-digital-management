from pydantic import BaseModel
from datetime import date

class MemberCreate(BaseModel): ## Class: Create new member 
    member_no: str
    full_name: str
    department: str | None = None
    join_date: date
    status: str = "ACTIVE"

class MemberUpdate(BaseModel): ## Class: Update new member 
    full_name: str
    department: str | None = None
    join_date: date
    status: str

class LoginRequest(BaseModel):
    username: str
    password: str

class TokenResponse(BaseModel): ## โครงสร้างของ Token Reseponse ที่ต้องสร้างให้ครบ
    access_token: str
    token_type: str
    role: str
    status: str