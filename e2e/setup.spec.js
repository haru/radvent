import { test } from '@playwright/test'
import { accounts, login, openPage, rememberLogin } from './support/accounts.js'
import { signUp } from './support/forms.js'

// Creates the accounts the scenario specs rely on besides alice and bob (see user-journey.spec.js).
// Sign-up is rate limited to 5 per hour: 4 accounts here and in the journey, 1 failed sign-up in auth.spec.js.
test.describe.serial('scenario accounts', () => {
  test('carol and dave sign up', async ({ browser }) => {
    for (const account of [accounts.carol, accounts.dave]) {
      const { page } = await openPage(browser)
      await signUp(page, account)
      await rememberLogin(page, account)
    }
  })

  test('the administrator logs in', async ({ browser }) => {
    const { page } = await openPage(browser)
    await login(page, accounts.admin)
    await rememberLogin(page, accounts.admin)
  })
})
