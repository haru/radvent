# End-to-end tests (Playwright)

Browser-driven tests that walk through the main user journey in a real
Chromium: first login, user registration, board and event creation, article
create / edit / delete, comments and likes. See
[ADR-0013](adr/0013-e2e-tests-with-playwright-and-dedicated-rails-env.md) for
why the setup looks like this.

## Prerequisites

```bash
bundle install
yarn install
yarn playwright install chromium   # add --with-deps if system libraries are missing
```

- Port 4500 must be free. A development server on port 3000 can keep running.

## Running

```bash
yarn e2e                         # everything
yarn e2e --headed                # watch the browser (debugging)
yarn playwright show-report      # open the HTML report of the last run
```

`yarn e2e` is one command. Playwright starts `build-scripts/e2e-server.sh`,
which

1. precompiles assets (into `public/e2e-assets`, not `public/assets`),
2. resets the E2E database (`db:drop`, `db:create`, `db:migrate`, `db:seed`),
3. serves the app in the `e2e` Rails environment on `127.0.0.1:4500`.

When the run ends, Playwright stops the server. The script fixes
`RAILS_ENV`, `DATABASE_URL` and `SECRET_KEY_BASE_DUMMY` itself; nothing needs to
be configured.

## What is reset

Only `db/radvent_e2e.sqlite3` (and its `-shm` / `-wal` files). Development and
test databases, `db/schema.rb` and `public/assets` are never touched. Mail uses
the `:test` delivery method and never leaves the machine.

## Reading a failure

| Situation | Exit code | What you see |
|-----------|-----------|--------------|
| Scenario failed | non-zero | failing test and step name (`AS 3-1 ...`), expected vs actual; later tests show as "did not run" |
| Port 4500 in use | non-zero | Playwright's "already used" error; no scenario runs |
| Asset build / DB reset / server start failed | non-zero | the script output and "webServer was not able to start" |
| Server not answering within 180 s | non-zero | webServer timeout |

Artifacts: `test-results/` (screenshot and trace of failed tests),
`playwright-report/` (HTML report), `log/e2e.log` (Rails log). All are
git-ignored.

## Notes

- E2E is not part of CI or `bundle exec rspec`; run it on demand.
- Stories run in order inside one `test.describe.serial` and hand data to the
  next story, so a failure stops the rest. There are no retries.
- Rate limits stay enabled. Each user logs in once and the login state is
  reused for later tests.

## Layout of the tests

| File | Role |
|------|------|
| `playwright.config.js` | port 4500, Chromium, `ja-JP` / `Asia/Tokyo`, failure artifacts, `webServer` |
| `e2e/user-journey.spec.js` | the scenarios: US2 (login, sign-up), US3 (board, events), US4 (articles), US5 (comments, likes). Each acceptance scenario is a `test.step` named `AS <story>-<n> ...` |
| `e2e/support/accounts.js` | the three test accounts, login / logout helpers, login-state reuse |
| `e2e/support/dates.js` | event periods computed from today's date in Tokyo |
| `e2e/support/editor.js` | typing into the EasyMDE (CodeMirror) editor |

Dates: the main events cover the whole previous month (every slot is already
published) and a second event covers days 1-7 of the same month two years
ahead (never published). The server's date is not manipulated.

Items (articles) have no required field: saving an empty title succeeds and the
article is shown as 無題. AS 4-6 therefore pins that behaviour down instead of
an input error.
