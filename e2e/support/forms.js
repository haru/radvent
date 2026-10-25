import { expect } from '@playwright/test'
import { userMenu } from './accounts.js'
import { fillMarkdown } from './editor.js'

// Fills in the sign-up form without submitting it.
export async function fillSignUp(page, { email, name, password, confirmation = password }) {
  await page.goto('/users/sign_up')
  await page.getByLabel('メールアドレス').fill(email)
  await page.getByLabel('名前').fill(name)
  await page.getByLabel('パスワード', { exact: true }).fill(password)
  await page.getByLabel('確認用パスワード').fill(confirmation)
}

export async function signUp(page, account) {
  await fillSignUp(page, account)
  await page.getByRole('button', { name: 'アカウント登録' }).click()
  await expect(userMenu(page)).toHaveText(account.name)
}

// Creates a board through the UI; ends on the board's page.
export async function createBoard(page, { boardId, name, visibility = '公開' }) {
  await page.goto('/boards/new')
  await page.getByLabel('ボードID').fill(boardId)
  await page.getByLabel('ボード名').fill(name)
  await page.getByRole('radio', { name: new RegExp(`^${visibility} —`) }).check()
  await page.getByRole('button', { name: '登録する' }).click()
  await expect(page.getByRole('heading', { name })).toBeVisible()
}

// The calendar cell of the given day of the event. Cells of neighbouring months show the same
// day numbers but carry neither a join button nor an author.
export function dayCell(page, day) {
  return page
    .locator('td', { has: page.locator('p.advent-calendar-date', { hasText: new RegExp(`^\\s*${day}\\s*$`) }) })
    .filter({ has: page.locator('.advent-calendar-author, .advent-calendar-join') })
}

// Joins the calendar on the given day; ends on that slot's page.
export async function joinDay(page, eventPath, day) {
  await page.goto(eventPath)
  await dayCell(page, day).getByRole('link', { name: '参加登録' }).click()
  await page.getByRole('button', { name: '登録する' }).click()
  await expect(page.getByRole('heading', { name: 'AdventCalendar情報' })).toBeVisible()
}

// From a slot page, writes and saves an article; ends back on the slot page.
export async function writeArticle(page, title, body) {
  await page.getByRole('link', { name: '記事を登録する' }).click()
  await page.getByLabel('タイトル').fill(title)
  await fillMarkdown(page, body)
  await page.getByRole('button', { name: '登録する' }).click()
  await expect(page.getByText('記事が登録されています')).toBeVisible()
}

export async function createEvent(page, event) {
  await page.getByRole('link', { name: 'イベントを作成' }).click()
  await page.getByLabel('名', { exact: true }).fill(event.name)
  await page.getByLabel('タイトル').fill(event.title)
  await page.getByLabel('開始日').fill(event.start)
  await page.getByLabel('終了日').fill(event.end)
  await page.getByRole('button', { name: '登録する' }).click()
  await expect(page.getByRole('heading', { name: event.title })).toBeVisible()
}

// Opens the board's page, then creates the event.
export async function createEventOn(page, boardPath, event) {
  await page.goto(boardPath)
  await createEvent(page, event)
}
