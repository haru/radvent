# Wiki Lint Report — 2026-10-25

Scope: full pass, 34 pages, 39 sources (S001–S039). No findings.

Resolved since the first pass of today (by editing pages at the user's request):
- e2e-testing.md: the `⚠ conflict` on the database reset (S038 R3 vs S039) was removed after `research.md` R3 was corrected to match ADR-0013 (each task in its own `rails` process, `SCHEMA` set to a non-existent file); both sources now agree (S038, S039).
- article-preview-authorization.md, project-origin.md: uncited bullets now cite S028 and S001.
- controllers-and-routing.md: frontmatter now lists S032 and S033, and `sources.md` lists the page for both.
- startup-log-secret-hygiene.md, event-addressing-by-board.md, protected-image-serving.md: S030, S030 and S022 are now cited where those sources state the claim.
- development-setup.md (S007) and domain-model.md (S004, S009, S012, S013): unused IDs removed from the frontmatter; the registry keeps them as historical "pages touched".
