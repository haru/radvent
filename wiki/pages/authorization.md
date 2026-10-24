---
title: Authorization
type: component
sources: [S002, S004, S009, S012, S013, S023, S024, S026, S027]
updated: 2026-10-24
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
admin (S004). Since feature `011-private-board-content-visibility`, the
`show` actions of Events, Items and AdventCalendarItems also run a
`check_visibility` filter that returns 404 unless the model's `visible?`
holds — see [Board Visibility on Show Pages](./show-page-visibility.md)
(S024). Full routing and controller breakdown in
[Controllers and Routing](./controllers-and-routing.md).

The design spec for user-created boards additionally calls for `Board`,
`Event`, `AdventCalendarItem`, `Item`, `Attachment`, and `Comment` to each
implement a `visible?(user)` / `editable?(user)` / `deletable?(user)`
interface, with admins always authorized, so that access control is
centralized per object rather than duplicated per controller (S009) — see
[User Boards & Multi-Event Support](./user-boards-feature.md) for the full
board-type rules and rationale.

Uploading an `Attachment` (via the editor's image-upload button) is gated by
the same `edit_permission?` check as the parent item (S012). *Viewing* an
uploaded image was originally unrestricted (feature `003-image-file-upload`,
S012); since feature `010-board-image-access-control`, new images are served
only to viewers for whom `Attachment#visible?` holds — the article's board
visibility plus the article being published (authors and admins exempt) — and
everyone else gets a 404. Images uploaded before that feature stay public, so
S012's "no view-time control" describes only those legacy images (S023).
See [Protected Image Serving](./protected-image-serving.md) (S023) and
[Toolbar Image Upload — UX and Access Control](./image-upload-toolbar-button.md).

Deleting a `Board` additionally requires typing the board's normalized ID
(case-insensitive, surrounding whitespace ignored) before the delete button
activates, re-verified server-side via
`Board#board_id_match?` — a defense-in-depth layer on top of the existing
`deletable?` gate. Full design, including the reversed decision to keep the
native browser confirm dialog alongside it, is in
[Board Deletion — ID Confirmation & Dialog](./board-delete-id-confirmation.md)
(S013).

Comments: only an admin or the owner of the item's board may delete a comment,
and posting requires the item to be readable (board visible *and* published,
with no exception for admins). Unreadable items answer 404, readable-but-not-
deletable answers 403. See [Comment Authorization](./comment-authorization.md)
(S026).

User-info editing is admin-only, and creating events, slots and articles
(and updating slots and articles) is authorized against the target
board/event/slot with 404 for hidden and 403 for forbidden targets; see
[User, Event, Slot and Article Authorization](./user-event-item-authorization.md)
(S027).

See [Domain Model](./domain-model.md) for the entities these rules apply to.
