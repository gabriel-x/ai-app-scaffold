// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
const request = require('supertest');
const { app } = require('../dist/app.js');

describe('auth contract', () => {
  it('health', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
  });
});

