---
title: Tech Stack
type: component
sources: [S001, S002, S005, S008]
updated: 2026-08-14
---

# Tech Stack

Radvent is a Ruby on Rails application. Core stack (S001):

| Category | Technology |
|----------|------------|
| Language | Ruby >= 3.3 |
| Framework | Ruby on Rails 8.1 |
| Frontend build | esbuild / PostCSS (Bootstrap 5 / mdb-ui-kit) / @hotwired/stimulus / Turbo |
| Templates | HAML |
| Markdown editor | EasyMDE (easy-markdown-editor) |
| Markdown parser | marked |
| Syntax highlighting | highlight.js |
| Authentication | Devise (`devise-bootstrap-views` + `devise-i18n-views` for styled, localized Devise pages) (S008) |
| DB (development) | SQLite3 |
| DB (production) | SQLite3 / MySQL 5.7+ / PostgreSQL |
| Testing | RSpec / FactoryBot / SimpleCov |
| CI | GitHub Actions |

The app ships with Japanese and English locales, switching automatically based
on the browser's language settings (S001), detected via the
`HttpAcceptLanguage::AutoLocale` module (S002).

The esbuild/PostCSS frontend build is wired into the Rails asset pipeline
through the `jsbundling-rails` and `cssbundling-rails` gems (S002), running
alongside Sprockets (legacy assets) as a dual pipeline — esbuild handles
modern JS modules (`node esbuild.config.mjs`), bundling into
`application_pack.css` and `application.js` (S005). Application versioning is
centralized in the `Radvent::Version` module (S002).

See [Views and Frontend](./views-and-frontend.md) for HAML/Stimulus/styling
conventions, [Domain Model](./domain-model.md) for what these models
represent, and [Project Origin](./project-origin.md) for why this stack was
chosen (fork of the original radvent project).
