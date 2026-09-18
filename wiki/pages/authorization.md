---
title: Authorization
type: component
sources: [S002, S004, S009, S012, S013]
updated: 2026-09-16
---

# Authorization

Split out of [Domain Model](./domain-model.md) (which covers entities and
authentication) once that page passed the wiki's 600-word split threshold.

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

Deleting a `Board` additionally requires typing the board's normalized ID
(case-insensitive, surrounding whitespace ignored) before the delete button
activates, re-verified server-side via
`Board#board_id_match?` — a defense-in-depth layer on top of the existing
`deletable?` gate. Full design, including the reversed decision to keep the
native browser confirm dialog alongside it, is in
[Board Deletion — ID Confirmation & Dialog](./board-delete-id-confirmation.md)
(S013).

See [Domain Model](./domain-model.md) for the entities these rules apply to.
