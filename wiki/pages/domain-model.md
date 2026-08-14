---
title: Domain Model
type: component
sources: [S001]
updated: 2026-08-14
---

# Domain Model

Entity relationships (S001):

```
Board ──< Event ──< AdventCalendarItem >── User
  │                       │
  └──< BoardMembership    └── Item ──< Comment
         >── User                └──< Like >── User
```

| Model | Description |
|-------|-------------|
| `User` | Devise-authenticated user. Has an admin flag |
| `Board` | Container for events. Two types: `top` (system-wide) and `user` (user-created), with `public` / `protected` / `private` visibility |
| `BoardMembership` | Join table between `Board` and `User` (membership management) |
| `Event` | Advent Calendar event. Belongs to a `Board` |
| `AdventCalendarItem` | Calendar date slot (`date` is an Integer 1–31) |
| `Item` | Markdown article. One-to-one with `AdventCalendarItem` |
| `Like` | Like on an article |
| `Comment` | Comment on an article. Stores `user_name` as a plain string, not a `User` reference |
| `Attachment` | File attachment via CarrierWave |

A `Board` can hold multiple `Event`s, meaning a single install supports
multiple concurrent Advent Calendar events with independent membership and
visibility (S001) — this is one of the additions this fork made over the
original project, see [Project Origin](./project-origin.md).

Built with the stack in [Tech Stack](./tech-stack.md).
