---
title: Domain Model
type: component
sources: [S001, S002, S003, S004, S006, S008, S009, S010, S012]
updated: 2026-08-14
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
| `User` | Devise-authenticated user. Requires `name` present. Has an `admin` boolean flag, checked via an `admin?` helper (S008) |
| `Board` | Container for events. Two types: `top` (system-wide) and `user` (user-created), with `public` / `protected` / `private` visibility. Routed by slug via `board_id` (S003) |
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
authorization ("what you can do") — see Authorization below (S008).

## Authorization

`ApplicationController` enforces admin-only actions with an `admin_user!`
filter that checks the `User#admin` boolean flag and renders 403 Forbidden
otherwise (S002, S004). `UsersController` renders admin-facing user-management
views through a separate admin layout from the public-facing templates
(S002). `BoardsController` restricts access per-board via a `check_visibility`
filter on the `visibility` enum, and Items/AdventCalendarItems controllers
gate edits with an `edit_permission?` guard limited to the creator or an
admin (S004). Full routing and controller breakdown in
[Controllers and Routing](./controllers-and-routing.md).

The design spec for user-created boards additionally calls for `Board`,
`Event`, `AdventCalendarItem`, `Item`, `Attachment`, and `Comment` to each
implement a `visible?(user)` / `editable?(user)` / `deletable?(user)`
interface, with admins always authorized, so that access control is
centralized per object rather than duplicated per controller (S009) — see
[User Boards & Multi-Event Support](./user-boards-feature.md) for the full
board-type rules and rationale.

Uploading an `Attachment` (via the editor's image-upload button) is gated by
the same `edit_permission?` check as the parent item, but *viewing* an
uploaded image's URL currently has no access control at all — anyone who
knows the URL can view it, independent of the item's visibility. Feature
`003-image-file-upload` confirms this is intentional (view-time
authorization is out of scope there), which is a gap relative to S009's
`visible?(user)` target for `Attachment` — see
[Toolbar Image Upload — UX and Access Control](./image-upload-toolbar-button.md)
(S012).

Built with the stack in [Tech Stack](./tech-stack.md).
