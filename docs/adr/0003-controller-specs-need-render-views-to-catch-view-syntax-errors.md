# 0003. Controller specs need render_views to catch view syntax errors

## Status

Accepted

## Context

`app/views/items/_form.html.haml` assembled the `editor_data` hash across
multiple lines from a leading `- editor_data = {` line. Haml only continues a
`-` script line implicitly when the line itself ends with a comma
(`Haml::Parser#is_ruby_multiline?`), so the template raised
`Haml::SyntaxError` on every render of `items#edit`.

The existing `GET #edit` controller spec still passed, because RSpec
controller specs stub view rendering by default: `render_template :edit`
only asserts which template was selected and never compiles or evaluates it.
The broken template therefore slipped through the whole test suite
(`bundle exec rspec spec`, all examples green) and was only discovered when
the screen was opened for real (see `specs/005-haml-render-smoke-test`).

## Decision

Whenever a controller spec is meant to prove that a screen actually renders
(a render smoke test), the spec must declare `render_views` in a dedicated
`context` block and assert the resulting HTTP status, following the
established pattern in `spec/controllers/boards_controller_spec.rb`
(`GET #index` / `GET #new`).

- Plain controller specs without `render_views` remain the default for
  status/assignment/redirect assertions; converting every existing spec is
  out of scope (YAGNI) and would slow the suite down.
- System specs (Capybara) are not required to catch template compile
  errors; `render_views` gives that coverage at a fraction of the cost.
- A `render_views` context must contain at least one test that performs a
  request against the action whose view should be smoke-tested.

Applied in this codebase: `spec/controllers/items_controller_spec.rb`
`GET #edit` gained a `context 'when rendering the view'` that renders the
edit form and asserts `have_http_status(:success)`.

## Consequences

- Template syntax errors in smoke-tested views now fail the normal test
  suite (verified Red→Green: stashing the Haml fix makes the new spec fail
  with `Haml::SyntaxError`, restoring it turns the spec green).
- Rolling `render_views` out to further controllers is a deliberate,
  per-controller decision; each user-facing screen should get its own
  render smoke test rather than enabling a blanket global `render_views`.
- Specs with `render_views` render the full layout and are slower; keep
  them focused (one context per action) to limit suite-time impact.
