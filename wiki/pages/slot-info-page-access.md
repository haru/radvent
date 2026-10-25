---
title: Slot Info Page — Author and Admin Only
type: decision
sources: [S032, S033]
updated: 2026-10-25
---

# Slot Info Page — Author and Admin Only

The slot info page (`GET /advent_calendar_items/:id`) is the author's
management page: it is the redirect target after saving a slot or an article,
hosts the slot edit/delete buttons, and shows whether an article is registered
— before the publish date. Feature `018-restrict-item-info-access` (Issue
#293) stopped it being a public read of that pre-publication state (S032, S033).

## Decisions

- **Reuse the edit-side filters**: `:show` was added to the `only:` lists of
  `before_action :authenticate_user!` and `before_action :edit_permission?`.
  No new method, model, view, route or i18n key; the permission rule stays
  `AdventCalendarItem#editable_by?` plus admins — authoring, not board
  standing, grants access (S032, S033). A show-specific check or a
  `viewable_by?` model method were rejected as duplication/YAGNI; hiding
  content in the view was rejected because a URL hit would still answer 200
  (S032).
- **Filter declaration order is kept**: `authenticate_user!` →
  `find_calendar_item` → `check_visibility` → `edit_permission?` →
  `find_board`. That order alone produces the contract: guests get a `302` to
  the sign-in page regardless of board type or slot existence; a signed-in
  viewer who cannot see the board (private-board non-member, including a
  removed member who authored the slot) gets `404` before any permission
  check; a viewer who can see the board but may not edit gets `403`; admins,
  the author, and — for account-less slots — a user whose name matches
  `user_name` get `200` (S032, S033).
- **Existence stays hidden**: the guest response is identical for a real slot
  and a non-existent one (same sign-in redirect), and `403`/`404` both halt
  before `find_board`, so the board name never reaches the layout (S032).
- **Replaces feature 011 for this page only**: the uniform-404 "no sign-in
  nudge" denial (see [Board Visibility on Show Pages](./show-page-visibility.md))
  remains in force for the calendar and article pages; the slot page is
  deliberately excluded as an authoring page (S032, S033). Recorded as
  ADR-0010 (S033).

## Consequences

- A non-editor can no longer learn whether a slot has an article before the
  publish date; the `403` page carries neither display name, comment, nor
  article buttons (S032).
- A board owner or member who is not the author loses direct access (previously
  `200`); the author's flows (save redirects, edit buttons) are unchanged
  (S032, S033).
