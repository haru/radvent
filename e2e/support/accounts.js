import fs from 'node:fs'
import path from 'node:path'
import { expect } from '@playwright/test'
import { watchJsErrors } from './js-errors.js'

export const accounts = {
  admin: { name: 'admin', email: 'admin@example.com', password: 'adminadmin' },
  alice: { name: 'e2e-alice', email: 'alice@e2e.example.com', password: 'alice-password' },
  bob: { name: 'e2e-bob', email: 'bob@e2e.example.com', password: 'bob-password' },
  carol: { name: 'e2e-carol', email: 'carol@e2e.example.com', password: 'carol-password' },
  dave: { name: 'e2e-dave', email: 'dave@e2e.example.com', password: 'dave-password' }
}

// Login states captured right after sign-up and reused for the rest of the run, so later tests do
// not post the login form again (the login and sign-up rate limits stay enabled).
// They are also written to disk, because the specs of one run share the accounts but may run in
// different worker processes. tmp/e2e is recreated by build-scripts/e2e-server.sh on every run.
const loginStates = {}
const statesDir = path.join('tmp', 'e2e', 'auth')
const statePath = (account) => path.join(statesDir, `${account.name}.json`)
const openedContexts = []

export const userMenu = (page) => page.locator('#navTopMenu .dropdown-toggle')

// Posts the login form and returns without checking the outcome.
export async function submitLogin(page, email, password) {
  await page.goto('/users/sign_in')
  await page.getByLabel('メールアドレス').fill(email)
  await page.getByLabel('パスワード', { exact: true }).fill(password)
  await page.getByRole('button', { name: 'ログイン' }).click()
}

export async function login(page, account) {
  await submitLogin(page, account.email, account.password)
  await expect(userMenu(page)).toHaveText(account.name)
}

export async function logout(page) {
  await userMenu(page).click()
  await page.getByRole('link', { name: 'ログアウト' }).click()
  await expect(page.getByRole('link', { name: 'ログイン' })).toBeVisible()
}

export async function rememberLogin(page, account) {
  loginStates[account.email] = await page.context().storageState()
  fs.mkdirSync(statesDir, { recursive: true })
  fs.writeFileSync(statePath(account), JSON.stringify(loginStates[account.email]))
}

function savedLogin(account) {
  if (!loginStates[account.email] && fs.existsSync(statePath(account))) {
    loginStates[account.email] = JSON.parse(fs.readFileSync(statePath(account), 'utf8'))
  }
  return loginStates[account.email]
}

// Opens a fresh browser context (closed by closeOpenedContexts) with its own page.
export async function openPage(browser, options = {}) {
  const context = await browser.newContext(options)
  openedContexts.push(context)
  watchJsErrors(context)
  return { context, page: await context.newPage() }
}

// Opens a fresh context whose page is already signed in as the given user.
export async function openAs(browser, account) {
  const state = savedLogin(account)
  if (!state) {
    throw new Error(`No saved login state for "${account.name}"`)
  }
  const opened = await openPage(browser, { storageState: state })
  await opened.page.goto('/')
  await expect(userMenu(opened.page)).toHaveText(account.name)
  return opened
}

export async function closeOpenedContexts() {
  await Promise.all(openedContexts.splice(0).map((context) => context.close()))
}
