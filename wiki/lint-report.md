# Wiki Lint Report — 2026-08-14

| # | Check | Severity | Page | Finding | Status |
|---|-------|----------|------|---------|--------|
| 1 | citations | semantic | user-boards-feature.md | The "Access control by board type" table (Public/Protected/Private × View/Create event) carried no source citation — neither a header citation nor inline per-row ones, unlike every other section on this page | **Fixed** — added `(S009)` to the section heading |

**index-drift**: none — all 9 files in `pages/` are listed in `INDEX.md` under the correct type, and no `INDEX.md` line points at a missing file.

**links**: none — every relative link (including `domain-model.md#authorization`) resolves to an existing page/anchor, and every `(Sxxx)` citation across all 9 pages names a source that exists in `sources.md` (S001–S009).

**orphans**: none — every page has at least one inbound link from another page (`INDEX.md` doesn't count as a link for this check).

**contradictions**: no unresolved `> ⚠ conflict:` markers, and no pairs of pages sharing a source assert incompatible claims. One open question is already surfaced in prose (not a hard contradiction): `domain-model.md` and `controllers-and-routing.md` both note that S009's proposed `visible?`/`editable?`/`deletable?` object interface and S004's `check_visibility`/`edit_permission?` controller filters aren't confirmed to be the same mechanism — this is a gap to verify against the actual code, not a factual conflict, so it's left as hedged prose rather than a `⚠ conflict:` marker.

**stale**: none — every page's `updated` is 2026-08-14 (today), and every cited source's `Last ingested` in `sources.md` is also 2026-08-14, so no page is out of sync with a re-ingested source.

## Mechanical fixes

`lint.auto_fix: index-and-links` — ran regeneration; `INDEX.md` was already an accurate reflection of `pages/` (0 lines changed), and no dead/renamed links were found to repair.
