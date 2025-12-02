# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Gabriel Xia(加百列)
FROM node:18-alpine
WORKDIR /app
COPY package.json package-lock.json* pnpm-lock.yaml* yarn.lock* ./
RUN npm i --legacy-peer-deps || true
COPY . ./
EXPOSE 5173
CMD ["npm","run","dev"]

