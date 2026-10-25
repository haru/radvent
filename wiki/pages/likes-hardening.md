---
title: Likes Hardening
type: decision
sources: [S028]
updated: 2026-10-24
---

# Likes Hardening

Feature `014-preview-email-exposure` (finding V-12) fixed `LikesController`,
which 500'd for guests, allowed likes on unreadable articles, and tolerated
duplicates (S028). Related: [Authorization](./authorization.md),
[Comment Authorization](./comment-authorization.md).

## Decisions

- **Gate order.** `authenticate_user!` (Turbo Stream requests redirect to
  sign-in too), then load `Item.find_by(id: params[:item_id])` and 404 unless
  `@item&.readable?(current_user)`. `Item#readable?` is the rule from feature
  012: viewable board and publish date reached, with no admin/owner exception.
  Missing and unreadable articles answer the same 404, including when
  withdrawing a like (S028).
- **Idempotent writes keyed by article + requester, not by like id.**
  `create` is `@item.likes.find_or_create_by(user: current_user)`; `destroy` is
  `@item.likes.where(user: current_user).destroy_all` (no-op when none, removes
  all of the requester's duplicates, never touches others). The route's `:id`
  is ignored, so a foreign like id cannot delete someone else's like (S028).
- **Uniqueness by validation only.** `Like` validates `user_id` unique per
  `item_id`, `on: :create`. No unique index and no cleanup migration: existing
  duplicates may make an index fail, which the constitution (XI) forbids; the
  rare concurrent double-create is tolerated (S028).
- **Count distinct users.** `Item#like_count` is
  `likes.distinct.count(:user_id)` and the liker list is de-duplicated, so
  existing duplicate rows do not inflate what is shown. The views
  (`items/_like`, `events/_detail`) use these; the withdraw button URL is built
  from the requester's own like on that article (S028).
- Rejected: `create!` rescuing `RecordInvalid` (exceptions as control flow),
  `likes.map(&:user).uniq` (N+1), a counter-cache column (migration plus
  backfill) (S028).

`Item#liked_users` is a `has_many :liked_users, -> { distinct.order(:id) },
through: :likes, source: :user` association, ordered by user id (S028).
