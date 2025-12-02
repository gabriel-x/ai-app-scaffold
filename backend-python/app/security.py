# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
import os
from fastapi import Request, HTTPException
from fastapi.security import HTTPBearer
from jose import jwt

security = HTTPBearer(auto_error=False)

async def auth_guard(request: Request):
    auth = await security.__call__(request)
    if not auth or not auth.credentials:
        raise HTTPException(status_code=401, detail={ 'code': 'UNAUTHORIZED', 'message': 'Missing token' })
    token = auth.credentials
    try:
        payload = jwt.decode(token, os.getenv('JWT_SECRET', 'dev-secret'), algorithms=['HS256'])
        request.state.user_id = payload.get('sub')
    except Exception:
        raise HTTPException(status_code=401, detail={ 'code': 'UNAUTHORIZED', 'message': 'Invalid token' })

