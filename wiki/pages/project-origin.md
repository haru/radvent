---
title: Project Origin
type: decision
sources: [S001]
updated: 2026-10-25
---

# Project Origin

Radvent is a fork of [nanonanomachine/radvent](https://github.com/nanonanomachine/radvent)
(original author: Yohei Koyama), maintained by haru (S001).

## What this fork added over upstream

- User authentication (Devise)
- Per-user event management: multiple boards with `public` / `protected` /
  `private` visibility and membership control (S001)
- Multiple Advent Calendar events (one `Board` can hold several `Event`s —
  see [Domain Model](./domain-model.md)) (S001)
- Likes and comments on articles
- File attachments (CarrierWave)

(S001)

These additions explain why the domain model carries `BoardMembership`,
`Like`, `Comment`, and `Attachment` as first-class models rather than the
upstream project's simpler structure — see [Domain Model](./domain-model.md)
and [Tech Stack](./tech-stack.md) for the resulting shape.
