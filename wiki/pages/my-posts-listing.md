---
title: My Posts Listing on My Page
type: decision
sources: [S042, S043, S044, S046]
updated: 2026-11-13
---

# My Posts Listing on My Page

Feature `025-my-past-posts` lists the signed-in user's own calendar slots on
My Page (`edit_user_registration_path`, i.e. `Users::RegistrationsController#edit`),
newest posting date first (S043).

## Placement: tabs inside the existing page

My Page is split with mdb-ui-kit 9.3.0 tabs (`data-mdb-tab-init`) into
"my posts" and "account settings"; no new Stimulus controller, because
`mdb.initMDB` already runs on every `turbo:load` (S042). The list data is
prepared by `before_action :load_my_posts, only: :edit`, and in `update` only
inside Devise's block when `resource.errors.any?`, because Devise re-renders
`edit` when `update` fails and a successful update redirects (S042). The view actually used is
`devise/registrations/edit.html.haml` — the `users/registrations/edit.html.erb`
file is unused because `Users::DeviseViews` empties `local_prefixes` (S042).

**Rejected**: a separate `/my/posts` page (contradicts the clarified spec);
server round-trip tabs via `?tab=` (clashes with the `/users` URL on failed
update); a custom Stimulus tab controller (YAGNI) (S042).

The account settings tab is first and always selected (feature 027 FR-001/FR-002,
superseding 025 FR-013); "my posts" follows and opens on click (S046). The
`settings_active = resource.errors.any?` branch was deleted: the error messages
sit inside the settings pane, so a failed `update` shows them with no tab
switching (S046). The controller is unchanged and `load_my_posts` still runs,
because the posts pane stays in the DOM (S046). The default briefly flipped in
`88927ff` and was reverted by convergence task T040 (S042).
Gotcha: the settings pane's `autofocus` email field now takes focus on first
paint, which may open the keyboard on mobile (S046). Selection is not
remembered via URL (YAGNI) (S046).

## Query and visibility

`AdventCalendarItem.posts_of(user)` loads `where(user_id:)` with
`joins(:event).preload(:item, event: :board)`, ordered in SQL by `events.start_date DESC`,
`date DESC`, `id DESC`, then filters in Ruby with `Board#visible?` (memoized
per board id so a private board costs one membership query) (S042). Same
reasoning as [Other Boards Listing](./other-boards-listing.md): `visible?` is
the single source of truth, so it is not re-expressed in SQL (S042). Legacy
slots with `user_id` NULL drop out naturally (S042). The likes of the page's
items are preloaded only for the 20 shown slots (in `assign_my_posts`), so
`Item#like_count` uses its `likes.loaded?` branch without per-row queries (S042).

**Rejected**: SQL visibility + `LIMIT/OFFSET` (duplicated logic);
`User has_many :advent_calendar_items` (drags in unrelated `dependent`
semantics) (S042).

## Status and link target

`AdventCalendarItem#post_status` returns `:published` (`published?`),
`:scheduled` (article exists but not yet published) or `:unwritten`; links go
to `item_path`, `edit_item_path` and `new_item_path(id:, date:)` respectively,
so existing per-action authorization still applies (S042). Gotcha:
`published?` no longer rescues impossible dates (e.g. the 31st of a 30-day
month); it raises `Date::Error` instead of hiding the bad data. Such rows are
now prevented at write time: `AdventCalendarItem` rejects a day missing from
the event month, `Event` requires `start_date`/`end_date`, and an `Event`
update is rejected when its new start month lacks a day used by an existing
slot (S042). Legacy rows predating these checks would still raise.

## Paging

20 cards per page; further pages load through a Turbo Frame "load more" from
`GET /my_posts?page=N` (`MyPostsController#index`, sign-in required, `page`
must be a plain run of digits ≥ 2, otherwise 422). Page-number validation was
extracted from `BoardOtherBoardsController` into the shared `LoadMorePage`
concern, used as `before_action :require_load_more_page` so a bad page halts
the request (S042).

## Display

Board name via `other_board_label`; the date is rendered from
`slot.year/month/date` through i18n rather than `Date.new`, which raises on
invalid dates; title via `Item#title` (S042). No ADR was written: everything
reuses existing patterns (S042).

See also [Article Search](./article-search.md), which reuses the same load-more concern and Ruby-side visibility filter (S044).

See [Controller Groups](./controller-groups.md) and
[Domain Model](./domain-model.md).
