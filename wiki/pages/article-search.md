---
title: Article Search from the Title Bar
type: decision
sources: [S044, S045]
updated: 2026-11-13
---

# Article Search from the Title Bar

Feature `026-article-search` adds a GET search form to the layout
(`#navTopMenu`, so it is folded into the hamburger menu below 992px) that opens
`GET /search?q=…` (`SearchesController#index`). It is open to guests (S044).

## Matching

`Item.search_readable(keywords, user)` matches each keyword against the title
or the body with `LOWER(col) LIKE LOWER(:p) ESCAPE '!'` (same form as
`Board::MATCH_SQL`), AND-ing the keywords; author, event, board and comment
text are not searched. Keywords are split on half- and full-width spaces; an
empty or blank keyword raises `ArgumentError` (model and helpers) rather than
matching everything (S044, S045).

## Visibility

Readability is decided in Ruby, not SQL: `Board#visible?` memoized per board
plus `AdventCalendarItem#published?`, the primitives behind `Item#readable?`.
They are combined separately, so a new `#readable?` condition must be mirrored
by hand; a spec compares both for every role (S045). So an
unpublished article is hidden even from its author and admins. Only ids and the
slot link are loaded for matches (`inverse_of: :item` on `belongs_to
:advent_calendar_item` avoids a query per slot); the total count is the number
of readable ids, so hidden articles never show in the count. Same reasoning as
[My Posts Listing](./my-posts-listing.md) (S044, S045).

**Rejected**: full-text index or search gem; SQL visibility rewrite (S045).

## Paging, limits, display

Results are 20 per page; `GET /search/page` returns a Turbo Frame fragment and
reuses `LoadMorePage`. `q` must be a string without control characters such as NUL (else 400) and at
most 100 characters after stripping (422 on the screen); empty `q` shows a
prompt. An enormous `page` gives an empty frame, not an error. Both actions
share one rate limit, 30 requests per minute per IP, answered with 429
(inside the frame for a valid `page`, the full 429 page otherwise; logged). Responses are `Cache-Control:
no-store`. Excerpts come from the Markdown source with whitespace squished
(about 120 characters around the first hit); `SearchesHelper#highlight_keywords`
escapes every fragment once (the excerpt itself is unescaped plain text) and
wraps the longest keyword match in `mark` (S044, S045). Decision
recorded in ADR-0015 (S045).

Known failure modes, kept explicit on purpose (S045): a slot whose date does not
exist in its month raises `Date::Error` and fails every search matching it; an
item deleted between the id query and the page query raises `KeyError`; DB
case folding and Ruby's differ on non-ASCII text, so a hit may show no
highlight.

Gotcha: the hamburger button needed `data-mdb-collapse-init` (mdb-ui-kit 9);
without it the menu, and so the search form, never opened on narrow screens (S044).

See [Controller Groups](./controller-groups.md) and
[Board Member Search](./board-member-search.md).
