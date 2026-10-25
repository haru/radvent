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
- The account lookup runs outside the rescue, so a database failure still
  surfaces as an error. Only the call to the user's
  `send_reset_password_instructions` (token generation and mail delivery) is
  wrapped in `rescue StandardError`. A failure is written to the log with
  `Rails.logger.error` (exception class only: SMTP errors often quote the
  recipient, so neither the message, the token, the address nor the mail body
  is logged), is passed to `Rails.error.report(handled: true)` for error
  trackers, and is not re-raised. This fallback is deliberate and documented
  here; it must not be removed as "swallowed exceptions".
- `config.paranoid` stays disabled. It would still accept blank input as sent,
  could not stop delivery exceptions from surfacing for registered addresses,
  and changes the sign-in failure handling, which is out of scope.
- Production mail settings are built from environment variables by
  `Radvent::MailSettings` (`RADVENT_URL`, `SMTP_*`, `RADVENT_MAIL_FROM`) and
  documented as required in the READMEs. The app still boots without them and
  prints a warning at boot naming the unset variables. A set but malformed
  value (a `RADVENT_URL` that is not an http(s) URL, a non-numeric `SMTP_PORT`,
  an unknown `SMTP_AUTHENTICATION`) fails the boot with a message naming the
  variable.

## Consequences

- A misconfigured mail setup is invisible to the visitor; operators must watch
  the log for `Password reset mail was not delivered`.
- Response timing is not equalized. A registered address is delivered
  synchronously inside the request, so it answers measurably slower than an
  unknown one, and much slower while the SMTP server is down or slow (until the
  SMTP timeout). An attacker who measures this can still tell registered
  addresses apart. Closing it needs asynchronous delivery (`deliver_later`),
  which is deferred because the job arguments would carry the raw reset token
  into the job logs and the default in-process queue loses jobs on restart; it
  should be revisited together with a real queue backend.
- Sign-up (`POST /users`) still answers "Email has already been taken" for a
  registered address, so account existence can also be learned there. This
  change covers password reset only.
- The delivery log line depends on `raise_delivery_errors` staying `true`
  (the default); development sets it to `false`, so the line does not appear
  there.
- Sign-in keeps its existing behavior: an unknown address and a wrong password
  get the same message.
