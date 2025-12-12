# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
from fastapi import APIRouter, Depends, HTTPException, Request
from ..security import auth_guard
from .auth import users

router = APIRouter()

@router.get('/profile')
async def profile(request: Request, _=Depends(auth_guard)):
    user_id = request.state.user_id
    for u in users.values():
        if u['id'] == user_id:
            return { 'id': u['id'], 'email': u['email'], 'name': u.get('name') }
    raise HTTPException(status_code=401, detail={ 'code': 'UNAUTHORIZED', 'message': 'Not found' })

@router.patch('/profile')
async def update_profile(request: Request, body: dict, _=Depends(auth_guard)):
    name = body.get('name')
    if not name:
        raise HTTPException(status_code=400, detail={ 'code': 'BAD_REQUEST', 'message': 'name required' })
    user_id = request.state.user_id
    for email, u in users.items():
        if u['id'] == user_id:
            users[email]['name'] = name
            return { 'id': u['id'], 'email': u['email'], 'name': name }
    raise HTTPException(status_code=401, detail={ 'code': 'UNAUTHORIZED', 'message': 'Not found' })

