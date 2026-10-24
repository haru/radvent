# 0008. Password reset hides account existence and delivery failure

## Status

Accepted

## Context

`POST /users/password` answered differently depending on the address: Devise
re-rendered the form with a "not found" error for an unregistered address and
redirected for a registered one, so anyone could enumerate registered
addresses. In production there was also no `default_url_options` and no SMTP
configuration, so for a registered address the mail always failed with
"Missing host" and the visitor saw an error page, which leaked the same fact.

## Decision

- `Users::PasswordsController#create` answers every well-formed address with
  the same `303` redirect and the same notice
  (`devise.passwords.send_paranoid_instructions`), whether or not an account
  exists and whether or not the mail could be sent. Only a blank or malformed
  address gets `422`, decided from the submitted string alone.
- The call to `send_reset_password_instructions` is wrapped in
  `rescue StandardError`. A delivery failure is written to the log with
  `Rails.logger.error` (exception class and message only, never the token, the
  address or the mail body) and is not re-raised. This fallback is deliberate
  and documented here; it must not be removed as "swallowed exceptions".
- `config.paranoid` stays disabled. It would still accept blank input as sent,
  could not stop delivery exceptions from surfacing for registered addresses,
  and changes the sign-in failure handling, which is out of scope.
- Production mail settings are built from environment variables by
  `Radvent::MailSettings` (`RADVENT_URL`, `SMTP_*`, `RADVENT_MAIL_FROM`) and
  documented as required in the READMEs. The app still boots without them.

## Consequences

- A misconfigured mail setup is invisible to the visitor; operators must watch
  the log for `Password reset mail was not delivered`.
- Response timing is not equalized; a registered address may still respond
  slightly slower. This is out of scope.
- Sign-in keeps its existing behavior: an unknown address and a wrong password
  get the same message.
