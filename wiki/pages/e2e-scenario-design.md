---
title: E2E Scenario Design
type: component
sources: [S038, S039]
updated: 2026-10-25
---

# E2E Scenario Design

How `e2e/user-journey.spec.js` and `e2e/support/*.js` are built. Environment and runner: [E2E Tests with Playwright](./e2e-testing.md).

## Structure

- One file, one `test.describe.serial`, with US2 → US3 → US4 → US5 as separate tests that hand data to the next one. A failing story makes later stories report "did not run" instead of failing for unrelated reasons (S038).
- Each acceptance scenario is a `test.step` named `AS <story>-<n> …`, one-to-one with the spec, so a failure names the scenario (S038, S039).
- Results are judged by what the screen shows, and data is created only through the UI, never by writing to the database (S038).

## Rate limits stay on

- Sign-in is limited to 10 per minute and sign-up to 5 per hour per IP (see [Authentication Rate Limits](./auth-rate-limit-and-lockout.md)); the limits are not disabled (S038).
- Users A and B register in dedicated browser contexts, and the login state (`context.storageState()`) is saved right after sign-up and reused for later stories, so only the login scenarios post the form. Reusing a logged-out session's cookie would break if the server ever revoked sessions (S038, S039).

## Dates without faking the clock

- `e2e/support/dates.js` takes today's date in Tokyo via `Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Tokyo' })`, because Node may run in UTC and the server decides publication in Tokyo time (S038).
- Past event: the whole previous month, so every slot is already published (`published?`) and a start and end in one month satisfy the event validation. Future event: days 1–7 of the same month two years ahead, never published during the run (S038).
- The browser context is `ja-JP` / `Asia/Tokyo`; the server date is never manipulated (S038).

## Locators and editor

- `getByRole` / `getByLabel` with the Japanese UI text; only unlabeled elements (the like button, the comment list) use existing ids and classes (S038).
- EasyMDE hides the textarea, so tests click `.CodeMirror` and type with the keyboard (S038).

## Failure reporting

- Screenshot and trace are kept on failure; an HTML report is written; `log/e2e.log` is emptied per run and mirrored to the terminal (S038, S039).
- Uncaught browser exceptions and `console.error` fail the test even if every assertion passed (S039).
- No scenario sends mail: the environment uses `:test` delivery and password-reset flows are out of scope (S038).
