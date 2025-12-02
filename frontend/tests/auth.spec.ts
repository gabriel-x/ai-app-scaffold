// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import { test, expect } from '@playwright/test'

test('登录路由保护与跳转', async ({ page }) => {
  await page.goto('/')
  await expect(page).toHaveURL(/login/)
})

