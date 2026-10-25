# 0012. Account lockout is time-based, invisible and does not end sessions

## Status

Accepted

## Context

Devise `:lockable` stops brute-force guessing against a known address (Issue
#289). Its defaults leak information or invite abuse: a distinct "account
locked" message reveals that an address is registered, an unlock mail enables
mail bombing, and an inactive-while-locked check logs out a victim whose
account an attacker locked. ADR-0008 already requires that responses never
reveal whether an account exists.

## Decision

- Lock after 10 consecutive failures for 15 minutes (`lock_strategy =
  :failed_attempts`, `unlock_strategy = :time`). The `failed_attempts` and
  `locked_at` columns already exist from the initial Devise migration, so no
  migration is needed. The `unlock_token` column stays unused: no unlock mail,
  and `devise_for :users` skips the unlock routes.
- The failure message for a locked account is the same as for a wrong password
  or an unknown address (`User#unauthenticated_message` maps `:locked` to
  `:invalid`, and both messages share one wording).
- `User#active_for_authentication?` stays true while locked, so a signed-in
  session is not cut. Only new authentication is refused.
- A successful password reset unlocks the account
  (`Users::PasswordsController#unlockable?` returns `true`).
- A lock is logged as `Account locked: user_id=<id>` (no address).

## Consequences

- An attacker can still lock a known account for 15 minutes at a time, but
  cannot tell whether it worked, cannot trigger mail, and cannot sign the owner
  out.
- A locked user's way out is waiting or resetting the password.
- ADR-0008 is unchanged and is the basis for the uniform responses.
