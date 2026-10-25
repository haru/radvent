import { expect } from '@playwright/test'

export const accounts = {
  admin: { name: 'admin', email: 'admin@example.com', password: 'adminadmin' },
  alice: { name: 'e2e-alice', email: 'alice@e2e.example.com', password: 'alice-password' },
  bob: { name: 'e2e-bob', email: 'bob@e2e.example.com', password: 'bob-password' }
}

// Login states kept for the whole run so that each user signs in through the form only once
// (the login rate limit stays enabled).
const loginStates = {}

export async function login(page, account) {
  await page.goto('/users/sign_in')
  await page.getByLabel('メールアドレス').fill(account.email)
  await page.getByLabel('パスワード', { exact: true }).fill(account.password)
  await page.getByRole('button', { name: 'ログイン' }).click()
  await expect(page.locator('#navTopMenu .dropdown-toggle')).toHaveText(account.name)
}

export async function logout(page) {
  await page.locator('#navTopMenu .dropdown-toggle').click()
  await page.getByRole('link', { name: 'ログアウト' }).click()
  await expect(page.getByRole('link', { name: 'ログイン' })).toBeVisible()
}

export async function rememberLogin(page, key) {
  loginStates[key] = await page.context().storageState()
}

// Opens a fresh browser context that is already signed in as the given user.
export async function openAs(browser, key) {
  if (!loginStates[key]) {
    throw new Error(`No saved login state for "${key}"`)
  }
  const context = await browser.newContext({
    storageState: loginStates[key],
    locale: 'ja-JP',
    timezoneId: 'Asia/Tokyo',
    baseURL: 'http://127.0.0.1:4500'
  })
  return { context, page: await context.newPage() }
}
