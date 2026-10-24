# Wiki Lint Report — 2026-10-24

Scope: full pass, 28 pages, 30 sources (S001–S030).

No findings.

Resolved since the previous pass (by editing the page at the user's request):
- domain-model.md: the `⚠ conflict` on `Event.name` uniqueness (S003 vs S029) was replaced with the verified behaviour — unique per board via the composite index on `[board_id, name]` (S029).
