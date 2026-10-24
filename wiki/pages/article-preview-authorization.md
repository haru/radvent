---
title: Article Preview Authorization
type: decision
sources: [S028]
updated: 2026-10-24
---

# Article Preview Authorization

Feature `014-preview-email-exposure` (finding V-06) closed the gap left open by
[User, Event, Slot and Article Authorization](./user-event-item-authorization.md):
the Markdown preview endpoints had no authorization and displayed a slot owner
chosen by the request (S028). General rules: [Authorization](./authorization.md).

## Decisions

- **Split the action.** `POST /items/preview` (no id) now routes to
  `items#preview_new`; the URL and the `preview_items_path` helper are
  unchanged, and the member `/items/:id/preview` stays `items#preview`. The old
  single action branched on `params[:id]`, so `before_action only:` could not
  target the two cases separately (S028).
- **Reuse the existing filters, no new rule.** `authenticate_user!` covers both
  previews; `check_article_creation_authorization` covers `preview_new` (same
  rule as article creation); `find_item`, `check_visibility` and
  `edit_permission?` cover `preview`. Order is unchanged, so an existing
  article answers 404 if missing, 404 if the board is not viewable, then 403 if
  the requester is neither admin nor the author (S028).
- **Hidden before forbidden.** `check_visibility` runs before
  `edit_permission?`, so a non-author never learns that an article on a private
  board exists (403 would reveal it); denial also happens before `find_board`,
  so the board name never reaches the layout (S028).
- **One params method.** The preview renders from `article_params` (`title` and
  `body` only); `preview_params` is deleted. Previously a requester could send
  another slot's `advent_calendar_item_id` and see that slot's owner name and
  date. Now the slot is the article's own (existing) or the one just
  authorized (new) (S028).
- Fields not sent keep their stored values, because `assign_attributes` only
  overwrites what is submitted; the edit form's hidden slot id is silently
  dropped by `params.expect` (S028).

## Rejected alternatives

- An `authorize_preview` method that calls the checks in turn: needs
  `performed?` guards and a second style next to the `before_action` chain.
- Lambda `if:`/`unless:` conditions: `new` also uses `params[:id]` as the slot
  id, so the condition becomes unreadable.
- Only "run `edit_permission?` when `params[:id]` is present": a non-author
  would get 403 on a hidden article, exposing it (S028).
