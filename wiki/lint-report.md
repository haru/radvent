# Wiki Lint Report — 2026-09-16

| # | Check | Severity | Page | Finding | Status |
|---|-------|----------|------|---------|--------|
| 1 | citations | semantic | easymde-editor-migration.md | The "## What changes" bullet list's last item, "Fullscreen mode is added as a toolbar option.", carried no source citation, unlike every other bullet on the page | **Fixed** — verified against `specs/002-easymde-editor/spec.md` (FR-005, User Story 4: fullscreen editing mode) and added `(FR-005) (S011)` |
| 2 | stale | semantic | controllers-and-routing.md, javascript-asset-pipeline.md, views-and-frontend.md | These three pages still described `ThemesController`, `theme_controller`, and the `data-theme` switching mechanism as "Planned"/"(planned)" after feature `007-theme-switch` merged, making the current-vs-planned framing stale | **Fixed** — reworded all three to present tense; the `prefers-color-scheme` media query is now documented as the System option's fallback rather than the sole mechanism |

**index-drift**: none — all 15 files in `pages/` are listed in `INDEX.md` under the correct type (7 component, 6 decision, 2 howto), and no `INDEX.md` line points at a missing file.

**links**: none — every relative link (including the new `authorization.md`, `theme-switch.md` links and the retargeted `controllers-and-routing.md#authorization-filters` / `views-and-frontend.md#styling` anchors) resolves to an existing page/heading, and every `(Sxxx)` citation across all 15 pages names a source that exists in `sources.md` (S001–S016).

**orphans**: none — every page has at least one inbound link from another page (`INDEX.md` doesn't count). `authorization.md`, split out of `domain-model.md` this session, is linked from 5 pages (`domain-model.md`, `controllers-and-routing.md`, `board-delete-id-confirmation.md`, `image-upload-toolbar-button.md`, `javascript-asset-pipeline.md`); `theme-switch.md` is linked from 4 (`domain-model.md`, `controllers-and-routing.md`, `views-and-frontend.md`, `javascript-asset-pipeline.md`).

**contradictions**: no unresolved `> ⚠ conflict:` markers, and no pairs of pages sharing a source assert incompatible claims. `views-and-frontend.md`, `javascript-asset-pipeline.md`, and `controllers-and-routing.md` previously described the S015 theme-switch work as "Planned" while feature `007-theme-switch` was still in flight; now that it has merged, all three describe `theme_controller`/`ThemesController`/the `data-theme` mechanism as current behavior, with the `prefers-color-scheme` media query documented as the System option's fallback rather than the sole mechanism. The previously-noted open question (S004's `check_visibility`/`edit_permission?` filters vs. S009's proposed object-level `visible?`/`editable?`/`deletable?` interface — not confirmed to be the same mechanism) remains hedged in prose in `authorization.md` and `user-boards-feature.md`, unchanged from the last report.

**stale**: none — every page's `updated` (2026-08-14 or 2026-09-16) is within `lint.stale_after_days` (90) of today, and no page's `updated` predates its cited sources' `Last ingested` dates in `sources.md`.

## Mechanical fixes

`lint.auto_fix: index-and-links` — ran regeneration; `INDEX.md` already matched `pages/` exactly (0 lines changed, including the `theme-switch.md` and `authorization.md` entries added during this session's ingest), and no dead or renamed links were found to repair.
