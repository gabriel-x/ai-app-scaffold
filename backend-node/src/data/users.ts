// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
export type User = { id: string; email: string; name?: string; passwordHash?: string }

const users = new Map<string, User>()

export const UsersRepo = {
  create(email: string, user: User) {
    users.set(email, user)
  },
  getByEmail(email: string) {
    return users.get(email)
  },
  getById(id: string) {
    for (const u of users.values()) {
      if (u.id === id) return u
    }
    return undefined
  },
  updateById(id: string, patch: Partial<User>) {
    for (const [email, u] of users.entries()) {
      if (u.id === id) {
        const next = { ...u, ...patch }
        users.set(email, next)
        return next
      }
    }
    return undefined
  },
  size() {
    return users.size
  }
}
