---
title: Board Member Search (Incremental Candidates)
type: decision
sources: [S040, S041]
updated: 2026-10-30
---

# Board Member Search (Incremental Candidates)

Feature `023-board-member-search` adds candidate suggestions to the member form of `BoardMembershipsController` (S040).

## Server

- `GET search` is a collection route under the board slug; it returns an HTML fragment rendered by a HAML partial, so escaping and `t()` strings stay on the server (S040).
- Access is owner and admin only (`editable?`); the rate limit (`rate_limit`, 60 per user per minute, shared across boards) is declared after the permission callbacks so rejected requests are not counted (S040, S041).
- A term under 2 characters (after stripping) answers 204; a non-string or over-255-character term answers 400. At most 10 candidates plus a "more" flag (limit + 1) are returned (S040).
- Matching is `LOWER(col) LIKE LOWER(:p) ESCAPE '!'` with `sanitize_sql_like(query, '!')`, so `%`, `_` and `!` are literal on SQLite, MySQL and PostgreSQL. SQLite's `LOWER` is ASCII only, so only ASCII case folding is guaranteed, and the sort order depends on the collation (S040).
- The owner and members are excluded through the `members` association; a NULL `user_id` row must not reach `NOT IN`, which would match nothing (S040).
- Responses are `no-store`; `member_query` is added to `filter_parameters` because the `email` filter does not match that name (S040, S041).

## Adding the picked user

- A hidden `user_id` carries the picked candidate, because names are not unique. A present `user_id` wins; an unknown or malformed one is an error and never falls back to the typed text (S040).
- Without an id, the typed text must match an email exactly or a unique name; several users with the same name is refused rather than picking one (S040).

## Client

- `member_search_controller` replaces the `stimulus-autocomplete` option, which lacked stale-response discard, IME handling and status-specific errors (S040).
- Any edit clears the selection and closes the old list at once; the search is debounced by 300 ms and the earlier request aborted. Esc, blur and `turbo:before-cache` cancel pending work and close the list (S040).
- IME composition does not search, and the Enter that confirms a conversion picks nothing (S040).
- Failures show distinct messages (rate limit, session expired, not permitted, generic) and are logged with `console.error`; they are never shown as "no match" (S040).

## Email exposure

Candidates show the name and full email, so any registered user who can own a board can discover addresses. This was accepted (2026-10-30) in ADR-0014 with the limits above; the rate limit slows but cannot stop slow harvesting, and the term still appears in proxy access logs (S041).

See [Authentication Rate Limits and Account Lockout](auth-rate-limit-and-lockout.md) for the shared limiter and [Controller Groups](controller-groups.md).
