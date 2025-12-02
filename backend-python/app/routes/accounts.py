# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
from fastapi import APIRouter, Depends, HTTPException
from ..security import auth_guard

router = APIRouter()

@router.get('/profile')
async def profile(_=Depends(auth_guard)):
    return { 'id': '1', 'email': 'demo@example.com', 'name': 'Demo' }

@router.patch('/profile')
async def update_profile(body: dict, _=Depends(auth_guard)):
    name = body.get('name')
    if not name:
        raise HTTPException(status_code=400, detail={ 'code': 'BAD_REQUEST', 'message': 'name required' })
    return { 'id': '1', 'email': 'demo@example.com', 'name': name }

