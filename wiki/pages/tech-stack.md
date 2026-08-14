---
title: Tech Stack
type: component
sources: [S001]
updated: 2026-08-14
---

# Tech Stack

Radvent is a Ruby on Rails application. Core stack (S001):

| Category | Technology |
|----------|------------|
| Language | Ruby >= 3.3 |
| Framework | Ruby on Rails 8.1 |
| Frontend build | esbuild / PostCSS (Bootstrap 5 / mdb-ui-kit) / @hotwired/stimulus |
| Templates | HAML |
| Markdown editor | EasyMDE (easy-markdown-editor) |
| Markdown parser | marked |
| Syntax highlighting | highlight.js |
| Authentication | Devise |
| DB (development) | SQLite3 |
| DB (production) | SQLite3 / MySQL 5.7+ / PostgreSQL |
| Testing | RSpec / FactoryBot / SimpleCov |
| CI | GitHub Actions |

The app ships with Japanese and English locales, switching automatically based
on the browser's language settings (S001).

See [Domain Model](./domain-model.md) for what these models represent, and
[Project Origin](./project-origin.md) for why this stack was chosen (fork of
the original radvent project).
