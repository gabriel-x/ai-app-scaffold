# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
FROM python:3.11-slim
WORKDIR /app
COPY app ./app
COPY pyproject.toml ./
RUN pip install --no-cache-dir fastapi uvicorn python-jose[cryptography] passlib[bcrypt] pydantic
ENV PORT=8000
EXPOSE 8000
CMD ["uvicorn","app.main:app","--host","0.0.0.0","--port","8000"]

