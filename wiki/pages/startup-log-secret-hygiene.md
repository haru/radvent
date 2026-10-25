---
title: Startup Log Secret Hygiene
type: decision
sources: [S029, S030]
updated: 2026-10-25
---

# Startup Log Secret Hygiene

Feature `015-env-log-event-collision` (V-13) stopped the container from
writing secrets to its startup logs (S029).

## Decisions

- **Two causes, not one.** `docker/run.sh` ran `env`, but the `Dockerfile`
  also ran `CMD sh -x ...`; the `-x` trace prints expanded values such as the
  `SECRET_KEY_BASE` test and the generated key export even after `env` is
  removed. Both `env` and `-x` had to go (S029, S030).
- **Keep progress visible without values.** Fixed `echo` lines before each
  stage (key generation, `db:create`, `db:migrate`, `db:seed`, puma) replace
  the trace; they never reference `SECRET_KEY_BASE` or `DB_PASSWORD`. `set -e`
  stays so a failed stage still aborts startup (S029).
- **Tested by reading files.** `spec/docker/startup_logging_spec.rb` asserts
  `run.sh` has no env-dump (`env`, `printenv`, `export -p`, bare `set`) or
  trace (`set -x`, `xtrace`) and no secret in `echo`, and that the `Dockerfile`
  has no `-x`. Running the script in RSpec was rejected (hard-coded absolute
  paths); container-log checks in CI were rejected as too large a change for a
  Low finding (S029).
- **Existing logs.** Secrets already logged are an operator concern: regenerate
  `SECRET_KEY_BASE` (for auto-generated keys, delete `/usr/local/keybase`) (S029).

See [Docker Deployment](./docker-deployment.md) and
[Configuration](./configuration.md); sibling fix:
[Event Addressing by Board](./event-addressing-by-board.md).
