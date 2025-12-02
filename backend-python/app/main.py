# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
import os
from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from .routes import auth, accounts

BASE = os.getenv('BASE_PATH', '/api/v1')

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=(os.getenv('ALLOWED_ORIGINS', '*').split(',')),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get('/health')
def health():
    return { 'status': 'ok' }

app.include_router(auth.router, prefix=f"{BASE}/auth")
app.include_router(accounts.router, prefix=f"{BASE}/accounts")

