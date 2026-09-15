---
title: User Boards & Multi-Event Support
type: decision
sources: [S009]
updated: 2026-08-14
---

# User Boards & Multi-Event Support

Spec for letting non-admin users create their own boards and run events on
them (`specs/001-user-boards/spec.md`, status Draft as of 2026-03-03) (S009).
This is the design behind the `Board`/`BoardMembership` shape already
summarized in [Domain Model](./domain-model.md).

## Board rules

- `board_id`: user-chosen, alphanumeric + `-`/`_`, max 64 chars, unique
  **case-insensitively** system-wide (`MyBoard` and `myboard` collide) —
  chosen over case-sensitive IDs to avoid confusing near-duplicate boards
  (S009).
- Reserved words (`boards`, `admin`, `users`, …) are rejected as `board_id`
  to avoid routing collisions (S009).
- Exactly one `TopBoard` exists system-wide, mounted at `/`; all pre-existing
  events belong to it. `UserBoard`s mount at `/boards/{board_id}` (S009).
- Board type (`public`/`protected`/`private`) is mutable after creation and
  takes effect immediately — the UI must warn the user beforehand that
  changing it changes who can see existing content (S009).
- Board deletion cascades to its events, articles, attachments, and comments;
  the UI must show an irreversibility warning before deleting (S009).
- Private-board content should carry a `noindex` meta tag (S009).

## Access control by board type (S009)

| Type | View | Create event |
|------|------|--------------|
| Public | anyone | any logged-in user |
| Protected | anyone | owner + members only |
| Private | owner + members only | owner + members only |

The board owner and site admins can always manage a board regardless of
type; admins can view/edit/delete **any** board including private ones
(S009) — this is a broader override than the `admin_user!` controller
filter in [Controllers and Routing](./controllers-and-routing.md); here it's
specified as a property of the permission checks themselves, not a
separate filter.

## Object-level permission interface

The spec requires `Board`, `Event`, `AdventCalendarItem`, `Item`,
`Attachment`, and `Comment` to each implement three methods —
`visible?(user)`, `editable?(user)`, `deletable?(user)` — and requires all
app-wide access control to route through them, evaluated against the
object's board type and the user's role (S009). This is a more general,
per-object design than the board-level `check_visibility` filter and the
item-level `edit_permission?` guard documented from the deepwiki source in
[Controllers and Routing](./controllers-and-routing.md) (S004) — those
filter names may be the controller-side callers of this model-level
interface, but that mapping isn't confirmed by either source.

## Constraints & out of scope

- Membership is owner-added only (by username/email) — join requests and
  invite links are explicitly out of scope for this version (S009).
- Board search/discovery and moving events between boards are out of scope
  (S009).
- All existing URLs (`/events/:name`, etc.) must keep working unchanged
  (S009).
- Devise itself is not modified by this feature (S009).

## UI additions

User dropdown menu gains "My page" and "Board management" entries; pages
under a `UserBoard` show a "TOP > {board_name}" breadcrumb (S009) — compare
the layout/navbar conventions in [Views and Frontend](./views-and-frontend.md).
