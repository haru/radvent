# Wiki Lint Report — 2026-10-24

| # | Check | Severity | Page | Finding | Status |
|---|-------|----------|------|---------|--------|
| 1 | contradictions | semantic | authorization.md | `> ⚠ conflict:` marker: S012 says image viewing has no access control; S023 says new images are controlled | **Fixed** — marker removed; text now states S012 describes only legacy images (S023) |
| 2 | contradictions | semantic | image-upload-toolbar-button.md | Same marker, plus a note saying viewing stays unrestricted and the specs "should be reconciled" | **Fixed** — marker replaced by a "Superseded for new images" paragraph; note rewritten as reconciled by feature 010 (S021) |
| 3 | stale | semantic | domain-model.md | Said Authorization covers "the image-upload access-control gap" | **Fixed** — now "image access control" |
| 4 | citations | semantic | easymde-editor-migration.md, image-upload-toolbar-button.md, user-boards-feature.md | Body cited S-ids missing from frontmatter `sources` | **Fixed** — added S012; S009 and S010; S004 respectively |

**index-drift**: none. All 18 files in `pages/` are listed in `INDEX.md` (including the new `protected-image-serving.md`) and no index line points at a missing file.

**links**: none. Every relative link resolves and every cited S-id (S001–S023) exists in `sources.md`.

**orphans**: none. `protected-image-serving.md` is linked from `authorization.md`, `image-upload-toolbar-button.md`, `configuration.md`, `docker-deployment.md`, `domain-model.md`, `controllers-and-routing.md`, and `javascript-asset-pipeline.md`.

**stale**: none after fix 3. No page is older than 90 days, and no page predates the `Last ingested` date of its sources.

**citations**: none after fix 4. The new page cites S021/S023 on every claim.

## Mechanical fixes

`lint.auto_fix: index-and-links`: `INDEX.md` already matched `pages/` and no dead links were found, so nothing was changed.
