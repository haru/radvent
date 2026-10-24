---
title: Comment Authorization (Posting and Deleting)
type: decision
sources: [S026]
updated: 2026-10-24
---

# Comment Authorization (Posting and Deleting)

Feature `012-comment-authorization` closed a gap where `CommentsController`
had no guard at all: anyone could delete any comment by ID, and anyone could
post to any item ID, including hidden or unpublished ones. The delete rule
(`Comment#deletable?`: admin or the owner of the item's board) already existed
but nothing called it, and the delete button was shown to everyone (S026).
General rules live in [Authorization](./authorization.md); routing in
[Controllers and Routing](./controllers-and-routing.md).

## Decisions

- **One "readable" predicate on `Item`.** `Item#readable?(user)` is
  `visible?(user) && advent_calendar_item.published?`. Both posting and the
  delete-rejection branch use it. Rejected: a private controller method (rule
  would not be readable from the model), and folding `published?` into
  `Item#visible?` (would change other callers such as `Attachment#visible?`)
  (S026).
- **Unpublished items are unreadable for everyone**, including admins, the
  board owner and the author; no edit-permission branch is needed (S026).
- **Delete order matters.** `destroy` checks, in order: comment missing → 404;
  `deletable?` → delete and redirect; item not readable → 404; otherwise 403.
  Checking readability first would stop owners and admins from cleaning up
  comments on unpublished items (S026).
- **404 vs 403.** Users who cannot read the item get the same 404 page as for
  a nonexistent record, so hidden items are not revealed. `Comment.find_by` plus
  an explicit `render_not_found` is used instead of `Comment.find`, because the
  raised `RecordNotFound` renders `public/404.html` in production, which looks
  different. Rejected: a global `rescue_from ActiveRecord::RecordNotFound`
  (changes other controllers; YAGNI) (S026).
- **Anonymous users** are not redirected to login: they get 403/404. Anonymous
  *posting* stays allowed on readable items (S026).
- **Never trust `item_id` on create.** The item is looked up once, authorized,
  and the comment is created through that same object
  (`item.comments.create(...)`), so the checked and the written item cannot
  differ (S026).
- **Delete button** is wrapped in `comment.deletable?(current_user)`, the same
  check the server enforces. `Item#comments` uses `inverse_of: :item`, so this
  adds no per-comment board query (S026).
- No ADR: the feature applies existing rules to unguarded places (S026).

## Gotcha

When this feature's research was written, `ItemsController#show` still checked
only `published?`, not board visibility; that gap was closed by the separate
feature 011, which added a `check_visibility` filter (S026, S024). See
[Board Visibility on Show Pages](./show-page-visibility.md).
