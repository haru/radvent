# 0010. Restrict the slot info page to its author and admins

## Status

Accepted

## Context

The slot info page (`GET /advent_calendar_items/:id`,
`AdventCalendarItemsController#show`) shows a participant's display name,
comment, and — before the publish date — whether an article is already
registered. It was guarded only by board visibility (`check_visibility`), so on
a public or protected board anyone, including guests, could read it, and the
article's existence leaked ahead of the publish date (Issue #293).

The page is in fact the author's management page: it is the redirect target
after saving a slot or an article, it hosts the slot edit and delete buttons,
and the article buttons on it are already hidden from non-editors. Earlier work
(feature 011) had standardized "denial is a uniform 404, no sign-in nudge" for
content pages; applying that shape here would still return 200 to guests on
public boards and would not stop the leak.

## Decision

- `show` joins the existing edit-side filters: `:show` is added to the `only:`
  lists of `before_action :authenticate_user!` and
  `before_action :edit_permission?`. No new method, model, view, route, or
  i18n key was introduced; the edit-permission rule
  (`AdventCalendarItem#editable_by?`, plus admins) is reused unchanged.
- The declaration order of the filters is kept:
  `authenticate_user!` → `find_calendar_item` → `check_visibility` →
  `edit_permission?` → `find_board`. The response therefore follows the
  contract table in `specs/018-restrict-item-info-access/`:
  1. Guest (regardless of board type or slot existence): `302` to the
     sign-in page, so existence is never revealed.
  2. Signed in, slot does not exist: `404`.
  3. Signed in, board not visible (private-board non-member, including a
     removed member who authored the slot): `404` — visibility is decided
     before permission, so a hidden board never leaks through a `403`.
  4. System admin: `200`.
  5. Editor (the author; for a slot without an account, a user whose name
     matches `user_name`): `200`.
  6. Any other signed-in user (including the board owner and members): `403`.
- This replaces the uniform-404 denial for the slot info page only. The
  calendar (`EventsController#show`) and article (`ItemsController#show`)
  pages keep their existing behavior, and the slot's `edit` / `update` /
  `destroy` and the save-redirect flows are untouched.

## Consequences

- The article's existence is no longer readable by non-editors before the
  publish date: unauthorized viewers get `302` / `403` / `404` and the `403`
  page carries neither the display name, the comment, nor the article buttons.
- A board owner or member who is not the slot's author loses direct access to
  the slot info page (previously `200`); admins keep access. Authoring, not
  board standing, grants access — `editable_by?` remains the single rule.
- Guests are now asked to sign in when opening any slot info page, including
  non-existent slots on private boards; the response is identical in both
  cases, so nothing about existence is disclosed.
- Feature 011's "denial is a uniform 404" remains in force for the calendar
  and article pages; the slot info page is deliberately excluded as an
  authoring page.
