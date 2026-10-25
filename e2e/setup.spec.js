import { test } from '@playwright/test'
import { accounts, login, openPage, rememberLogin } from './support/accounts.js'
import { signUp } from './support/forms.js'

// Creates the accounts the scenario specs rely on besides alice and bob (see user-journey.spec.js).
// Sign-up is rate limited to 5 per hour per client address: 4 accounts here and in the journey, 1 failed
// sign-up in auth.spec.js. eve signs up from another client address (X-Forwarded-For is honoured for the
// loopback client) so that she does not use up that budget.
test.describe.serial('scenario accounts', () => {
  test('carol and dave sign up', async ({ browser }) => {
    for (const account of [accounts.carol, accounts.dave]) {
      const { page } = await openPage(browser)
      await signUp(page, account)
      await rememberLogin(page, account)
    }
  })

  // The sign-up rate limit is keyed on request.remote_ip, which honours X-Forwarded-For from the
  // loopback client; another address keeps eve out of the limit shared by the other sign-ups.
  test('eve signs up from another address', async ({ browser }) => {
    const { page } = await openPage(browser, { extraHTTPHeaders: { 'X-Forwarded-For': '203.0.113.7' } })
    await signUp(page, accounts.eve)
    await rememberLogin(page, accounts.eve)
  })

  test('the administrator logs in', async ({ browser }) => {
    const { page } = await openPage(browser)
    await login(page, accounts.admin)
    await rememberLogin(page, accounts.admin)
  })
})
