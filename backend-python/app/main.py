# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
import os
from fastapi import FastAPI, Depends, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
import time
import logging
from .routes import auth, accounts

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("scaffold")

BASE = os.getenv('BASE_PATH', '/api/v1')

app = FastAPI()

@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = (time.time() - start_time) * 1000
    logger.info(f"{request.method} {request.url.path} {response.status_code} {process_time:.2f}ms")
    return response

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

