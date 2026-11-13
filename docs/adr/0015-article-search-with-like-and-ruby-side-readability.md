# 0015. Article search with LIKE and a Ruby-side readability check

## Status

Accepted

## Context

The title bar gets a keyword search over article titles and bodies (spec 026).
Results must never include an article the viewer cannot open, not even in the
total count, and guests may search too.

## Decision

- Match with `LOWER(col) LIKE LOWER(:p) ESCAPE '!'` on the title and the body,
  one condition per keyword joined with AND (the same form as
  `Board::MATCH_SQL`). No full-text index and no search gem.
- Decide readability in Ruby with `Board#visible?` (memoized per board) and
  `AdventCalendarItem#published?`, the rules behind `Item#readable?`, instead
  of rewriting them in SQL. Only ids are loaded for the matches; bodies are
  read for the 20 items of the page being shown.
- Rate-limit `/search` and `/search/page` together to 30 requests per minute
  per IP address (`rate_limit`, counters as in ADR-0011). Guests are limited
  too, so the limit is per IP, not per user.
- Build excerpts from the Markdown source as written (whitespace squished),
  escape every fragment separately and wrap keyword matches in `mark`.

## Consequences

- A partial-match scan is fine at the current scale (about 1,000 articles in
  well under 2 seconds) but will need a real index if the data grows a lot.
- Search reuses the primitives behind `Item#readable?` (`Board#visible?` and
  `AdventCalendarItem#published?`) but combines them separately in
  `Item.search_readable`. A new condition added to `Item#readable?` must be
  mirrored there; `spec/models/item_search_readable_spec.rb` checks that both
  agree for every role.
- A matched slot whose date does not exist in its month raises `Date::Error`,
  so one such legacy row makes every search that matches it fail with a 500
  for every viewer. This is kept explicit (no rescue); clean the data instead.
- The page ids and the page items come from two queries, so an item deleted
  in between raises `KeyError` (a 500, deliberately not hidden).
- Matching is done by the database (`LOWER` / collation) while highlighting is
  done by Ruby's Unicode-aware case folding, so on non-ASCII text a hit can
  show no highlight and an excerpt from the head of the body.
- All matches of a query are loaded as ids before paging, so very broad
  keywords cost more than narrow ones.
- Clients behind one shared IP address share a limit.
