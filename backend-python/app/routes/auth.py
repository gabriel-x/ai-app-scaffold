# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
import os
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, EmailStr
from passlib.context import CryptContext
from jose import jwt

router = APIRouter()
pwd = CryptContext(schemes=["bcrypt"], deprecated="auto")

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
    users[body.email] = {
        'id': str(len(users) + 1),
        'email': body.email,
        'name': body.name,
        'passwordHash': pwd.hash(body.password)
    }
    u = users[body.email]
    return { 'ok': True, 'data': { 'id': u['id'], 'email': u['email'], 'name': u.get('name') } }

@router.post('/login')
def login(body: LoginRequest):
    u = users.get(body.email)
    if not u or not pwd.verify(body.password, u['passwordHash']):
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
def me(token: str | None = None):
    # 为简化演示，直接返回固定示例；真实实现应读取 user_id 并查询
    return { 'id': '1', 'email': 'demo@example.com', 'name': 'Demo' }

