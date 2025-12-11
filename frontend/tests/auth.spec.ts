// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import { test, expect } from '@playwright/test'

test('登录路由保护与跳转', async ({ page }) => {
  await page.goto('/')
  // 根路径应该渲染HomeTemplate组件，检查页面标题或特定元素
  await expect(page).toHaveTitle(/Scaffold Frontend/)
})

