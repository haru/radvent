---
title: Domain Model
type: component
sources: [S001, S002, S003, S004, S006, S008, S009, S010, S012, S013, S015, S019]
updated: 2026-09-18
---

# Domain Model

Radvent is an Advent Calendar-style blog application: users join events,
claim specific calendar dates, and publish Markdown articles that become
visible automatically once their claimed date passes (S002).

Entity relationships (S001):

```
Board ──< Event ──< AdventCalendarItem >── User
  │                       │
  └──< BoardMembership    └── Item ──< Comment
         >── User                └──< Like >── User
```

| Model | Description |
|-------|-------------|
| `User` | Devise-authenticated user. Requires `name` present. Has an `admin` boolean flag, checked via an `admin?` helper (S008). Feature `007-theme-switch` adds a `theme` enum (`system`/`light`/`dark`, string-backed, default `system`) controlling UI theme — see [Manual Theme Selection](./theme-switch.md) (S015) |
| `Board` | Container for events. Two types: `top` (system-wide) and `user` (user-created), with `public` / `protected` / `private` visibility. Routed by slug via `board_id` (S003). Feature `009-board-list` adds `#list_sort_key`, an instance method ranking a board by its newest published-item activity — see [Other Boards Listing](./other-boards-listing.md) (S019) |
| `BoardMembership` | Join table between `Board` and `User` (membership management, owner-added only) |
| `Event` | Advent Calendar event. Belongs to a `Board`. `name` doubles as the routing slug; `title` and `name` both have unique indexes (S003) |
| `AdventCalendarItem` | Calendar date slot (`date` is an Integer 1–31). Exposes a `published?` method that gates visibility once the claimed date passes (S006) |
| `Item` | Markdown article. One-to-one with `AdventCalendarItem` |
| `Like` | Like on an article |
| `Comment` | Comment on an article. Stores `user_name` as a plain string, not a `User` reference |
| `Attachment` | File attachment via CarrierWave (`ImageUploader`); created by the editor's image-upload endpoint — see [JavaScript and CSS Asset Pipeline](./javascript-asset-pipeline.md) (S010) |

A `Board` can hold multiple `Event`s, meaning a single install supports
multiple concurrent Advent Calendar events with independent membership and
visibility (S001) — this is one of the additions this fork made over the
original project, see [Project Origin](./project-origin.md).

## Authentication

`User` enables Devise's `database_authenticatable`, `registerable`,
`rememberable` (`remember_created_at`), `trackable` (sign-in counts,
timestamps, IPs), `validatable`, `timeoutable` (auto-expires inactive
sessions), and `recoverable` (password reset) modules (S008). Password
hashing uses bcrypt with environment-dependent stretch cost — 1 in test, 12
elsewhere (S008; matches the testing-config note in
[Development Setup](./development-setup.md)). The authentication key (email)
is matched case-insensitively with whitespace stripped (S008). Devise
handles authentication ("who you are"); the `admin` flag drives application
authorization ("what you can do") — see [Authorization](./authorization.md)
(S008).

## Authorization

Devise handles authentication; a separate `admin` flag and a set of
controller-level filters and object-level rules drive authorization — moved
to its own page once this one passed the wiki's word-count split threshold.
See [Authorization](./authorization.md) for admin filters, board visibility,
edit/delete gating, and the image-upload access-control gap.

Built with the stack in [Tech Stack](./tech-stack.md).
