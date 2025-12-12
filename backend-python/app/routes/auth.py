# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
import os
import bcrypt
from fastapi import APIRouter, HTTPException, Request, Depends
from pydantic import BaseModel, EmailStr
from jose import jwt
from ..security import auth_guard

router = APIRouter()

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    name: str | None = None

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

users: dict[str, dict] = {}

def sign_tokens(user_id: str):
    secret = os.getenv('JWT_SECRET', 'dev-secret')
    access = jwt.encode({ 'sub': user_id }, secret, algorithm='HS256')
    refresh = jwt.encode({ 'sub': user_id, 'type': 'refresh' }, secret, algorithm='HS256')
    return { 'accessToken': access, 'refreshToken': refresh }

@router.post('/register')
def register(body: RegisterRequest):
    if body.email in users:
        raise HTTPException(status_code=400, detail={ 'code': 'ALREADY_EXISTS', 'message': 'Email exists' })
    # Truncate password to max 72 bytes for bcrypt
    truncated_password = body.password[:72]
    # Hash password using bcrypt directly
    hashed_password = bcrypt.hashpw(truncated_password.encode('utf-8'), bcrypt.gensalt())
    users[body.email] = {
        'id': str(len(users) + 1),
        'email': body.email,
        'name': body.name,
        'passwordHash': hashed_password.decode('utf-8')
    }
    u = users[body.email]
    return { 'ok': True, 'data': { 'id': u['id'], 'email': u['email'], 'name': u.get('name') } }

@router.post('/login')
def login(body: LoginRequest):
    u = users.get(body.email)
    # Truncate password to max 72 bytes for bcrypt (same as registration)
    truncated_password = body.password[:72]
    if not u or not bcrypt.checkpw(truncated_password.encode('utf-8'), u['passwordHash'].encode('utf-8')):
        raise HTTPException(status_code=401, detail={ 'code': 'UNAUTHORIZED', 'message': 'Invalid credentials' })
    return sign_tokens(u['id'])

@router.post('/refresh')
def refresh(body: dict):
    try:
        payload = jwt.decode(body.get('refreshToken'), os.getenv('JWT_SECRET', 'dev-secret'), algorithms=['HS256'])
        if payload.get('type') != 'refresh':
            raise Exception('invalid')
        tokens = sign_tokens(payload.get('sub'))
        return tokens
    except Exception:
        raise HTTPException(status_code=401, detail={ 'code': 'UNAUTHORIZED', 'message': 'Invalid refresh token' })

@router.get('/me')
async def me(request: Request, _=Depends(auth_guard)):
    user_id = request.state.user_id
    for u in users.values():
        if u['id'] == user_id:
            return { 'id': u['id'], 'email': u['email'], 'name': u.get('name') }
    raise HTTPException(status_code=401, detail={ 'code': 'UNAUTHORIZED', 'message': 'Not found' })

