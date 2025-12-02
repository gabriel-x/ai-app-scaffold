# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
from fastapi.testclient import TestClient
from app.main import app

def test_health():
    c = TestClient(app)
    r = c.get('/health')
    assert r.status_code == 200

