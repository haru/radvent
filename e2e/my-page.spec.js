import { test, expect } from '@playwright/test'
import { accounts, closeOpenedContexts, openAs } from './support/accounts.js'
import { futureEventPeriod, pastEventPeriod } from './support/dates.js'
import { createBoard, createEvent, joinDay, writeArticle } from './support/forms.js'
import { clearJsErrors, expectNoJsErrors, watchJsErrors } from './support/js-errors.js'

const board = { boardId: 'e2e-my-page', name: 'E2E マイページボード', visibility: '公開' }
const pastEvent = { name: 'e2e-my-page-past', title: 'E2E マイページ過去', ...pastEventPeriod() }
const futureEvent = { name: 'e2e-my-page-future', title: 'E2E マイページ未来', ...futureEventPeriod() }
const eventPath = (event) => `/boards/${board.boardId}/events/${event.name}`

const postsRow = (page, text) => page.locator('#my-page-posts tr', { hasText: text })

test.describe.serial('マイページ', () => {
  test.beforeEach(async ({ page }) => {
    clearJsErrors()
    watchJsErrors(page.context())
  })

  test.afterEach(async () => {
    await closeOpenedContexts()
    expectNoJsErrors()
  })

  test('準備: bob のボードに公開済み・公開前・未執筆の枠を用意する', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.bob)
    await createBoard(page, board)
    await createEvent(page, pastEvent)
    await createEvent(page, futureEvent)
    await joinDay(page, eventPath(pastEvent), 3)
    await writeArticle(page, 'E2E マイページ公開済み記事', '本文')
    await joinDay(page, eventPath(futureEvent), 1)
    await writeArticle(page, 'E2E マイページ公開前記事', '本文')
    await joinDay(page, eventPath(futureEvent), 2)
  })

  test('M-1 自分の投稿: 公開済みの記事がステータス付きで並び、タイトルから記事を開ける', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.bob)
    await page.goto('/users/edit')
    await expect(page.locator('#my-page-posts-tab')).toHaveAttribute('aria-selected', 'true')
    const row = postsRow(page, 'E2E マイページ公開済み記事')
    await expect(row).toContainText('公開済み')
    await expect(row).toContainText(board.name)
    await expect(row).toContainText(pastEvent.title)
    await row.getByRole('link', { name: 'E2E マイページ公開済み記事' }).click()
    await expect(page).toHaveURL(/\/items\/\d+$/)
  })

  test('M-2 公開前の記事は編集画面へ、未執筆の枠は記事作成画面へ進める', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.bob)
    await page.goto('/users/edit')
    const scheduled = postsRow(page, 'E2E マイページ公開前記事')
    await expect(scheduled).toContainText('公開前')
    await scheduled.getByRole('link', { name: 'E2E マイページ公開前記事' }).click()
    await expect(page).toHaveURL(/\/items\/\d+\/edit$/)

    await page.goto('/users/edit')
    const unwritten = postsRow(page, futureEvent.title).filter({ hasText: '未執筆' })
    await expect(unwritten).toContainText(futureEvent.title)
    await unwritten.getByRole('link', { name: '記事を書く' }).click()
    await expect(page).toHaveURL(/\/items\/new/)
  })

  test('M-3 アカウント設定タブにフォーム・テーマ・アカウント削除がある', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.bob)
    await page.goto('/users/edit')
    await page.locator('#my-page-settings-tab').click()
    await expect(page.locator('#my-page-settings')).toBeVisible()
    await expect(page.getByLabel('現在のパスワード')).toBeVisible()
    await expect(page.locator('#theme_dark')).toBeVisible()
    await expect(page.getByRole('button', { name: 'アカウント削除' })).toBeVisible()
    await expect(page.locator('#my-page-posts')).toBeHidden()
  })

  test('M-4 保存に失敗すると、エラー付きでアカウント設定タブが選ばれて再表示される', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.bob)
    await page.goto('/users/edit')
    await page.locator('#my-page-settings-tab').click()
    await page.getByLabel('名前').fill('e2e-bob-renamed')
    await page.getByLabel('現在のパスワード').fill('wrong-password')
    await page.locator('form[action="/users"] input[type=submit]').click()
    await expect(page.locator('.alert-danger')).toBeVisible()
    await expect(page.locator('#my-page-settings-tab')).toHaveAttribute('aria-selected', 'true')
    await expect(page.locator('#my-page-posts-tab')).toHaveAttribute('aria-selected', 'false')
  })
})
