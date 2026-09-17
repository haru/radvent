# Source Registry

Append-only IDs (S001, S002…). Dedup key: normalized path or URL.
Sources are immutable inputs — the wiki never edits them.

| ID | Source | Type | First ingested | Last ingested | Pages touched |
|----|--------|------|----------------|---------------|---------------|
| S001 | README.md | file | 2026-08-14 | 2026-08-14 | tech-stack.md, domain-model.md, project-origin.md, development-setup.md, docker-deployment.md |
| S002 | https://deepwiki.com/haru/radvent/1-radvent-overview | url | 2026-08-14 | 2026-08-14 | tech-stack.md, domain-model.md |
| S003 | https://deepwiki.com/haru/radvent/2-core-data-model | url | 2026-08-14 | 2026-08-14 | domain-model.md |
| S004 | https://deepwiki.com/haru/radvent/3-controllers-and-routing | url | 2026-08-14 | 2026-08-14 | controllers-and-routing.md, domain-model.md |
| S005 | https://deepwiki.com/haru/radvent/4-views-and-frontend | url | 2026-08-14 | 2026-08-14 | views-and-frontend.md, tech-stack.md |
| S006 | https://deepwiki.com/haru/radvent/5-testing | url | 2026-08-14 | 2026-08-14 | development-setup.md, domain-model.md |
| S007 | https://deepwiki.com/haru/radvent/1.2-configuration-reference | url | 2026-08-14 | 2026-08-14 | configuration.md, docker-deployment.md, development-setup.md |
| S008 | https://deepwiki.com/haru/radvent/2.4-user-model-and-authentication | url | 2026-08-14 | 2026-08-14 | domain-model.md, tech-stack.md |
| S009 | specs/001-user-boards/spec.md | feature-artifact | 2026-08-14 | 2026-08-14 | user-boards-feature.md, domain-model.md, controllers-and-routing.md |
| S010 | https://deepwiki.com/haru/radvent/4.3-javascript-and-css-asset-pipeline | url | 2026-08-14 | 2026-08-14 | javascript-asset-pipeline.md, views-and-frontend.md, domain-model.md |
| S011 | specs/002-easymde-editor/spec.md | feature-artifact | 2026-08-14 | 2026-08-14 | easymde-editor-migration.md, views-and-frontend.md, javascript-asset-pipeline.md |
| S012 | specs/003-image-file-upload/spec.md | feature-artifact | 2026-08-14 | 2026-08-14 | image-upload-toolbar-button.md, javascript-asset-pipeline.md, domain-model.md, easymde-editor-migration.md |
| S013 | specs/006-board-delete-id-confirm/research.md | feature-artifact | 2026-09-16 | 2026-09-16 | board-delete-id-confirmation.md, domain-model.md, controllers-and-routing.md, javascript-asset-pipeline.md |
| S014 | specs/006-board-delete-id-confirm/plan.md (decision sections) | feature-artifact | 2026-09-16 | 2026-09-16 | board-delete-id-confirmation.md |
| S015 | specs/007-theme-switch/research.md | feature-artifact | 2026-09-16 | 2026-09-16 | theme-switch.md, domain-model.md, controllers-and-routing.md, views-and-frontend.md, javascript-asset-pipeline.md |
| S016 | specs/007-theme-switch/plan.md (decision sections) | feature-artifact | 2026-09-16 | 2026-09-16 | theme-switch.md |
| S017 | specs/008-fix-dark-theme/research.md | feature-artifact | 2026-09-17 | 2026-09-17 | dark-theme-full-coverage.md, devise-views-format-conversion.md, views-and-frontend.md, javascript-asset-pipeline.md, theme-switch.md |
| S018 | specs/008-fix-dark-theme/plan.md (decision sections) | feature-artifact | 2026-09-17 | 2026-09-17 | dark-theme-full-coverage.md |

Note: domain-model.md exceeded the 600-word split threshold after S015's
update; its Authorization section was split into authorization.md (S002,
S004, S009, S012, S013 — no new source). Links in
image-upload-toolbar-button.md, javascript-asset-pipeline.md,
controllers-and-routing.md, and board-delete-id-confirmation.md were
retargeted to the new page accordingly.

Note: dark-theme-full-coverage.md exceeded the 600-word split threshold on
creation from S017; its Devise ERB→HAML/`.panel`→`.card` section (which also
carries an implementation-flag conflict) was split into
devise-views-format-conversion.md (S017 — no new source).
