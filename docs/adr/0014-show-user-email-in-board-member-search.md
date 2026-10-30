# 0014. Show user email addresses in the board member search

## Status

Accepted

## Context

The member management screen gets an incremental search (spec 023). To tell
apart users who share a name, and to find a user by a hint such as part of an
address, each candidate shows the user name and the full email address. Any
registered user can create a board and become its owner, so this lets any
registered user look up other users' email addresses. Earlier work (ADR-0008,
spec 014) reduced account-existence and address leaks, so addresses were not
browsable until now.

## Decision

- Accept the exposure for convenience (decided 2026-10-30). Search is limited
  to users who can manage the board's members (owner and admins), requires at
  least 2 characters, returns at most 10 candidates, and is limited to 60
  searches per user per minute (`rate_limit`, counters as in ADR-0011).
- Responses carry only the id, name and email address, are sent with
  `Cache-Control: no-store`, and the search term (`member_query`) is filtered
  from the Rails request logs. Reverse-proxy access logs still see it, because
  it is sent in the GET query string.

## Consequences

- The rate limit slows bulk harvesting but cannot stop a slow, sustained one.
- Partial matching lets a registered user discover addresses they did not
  already know; confirming a known address was already possible through the
  exact-match add and sign-up. Revisit this ADR with a superseding one if the exposure becomes
  unacceptable (for example, by showing masked addresses).
