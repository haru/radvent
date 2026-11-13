import { test, expect } from '@playwright/test'
import { accounts, closeOpenedContexts, openAs } from './support/accounts.js'
import { futureEventPeriod, pastEventPeriod } from './support/dates.js'
import { createBoard, createEvent, joinDay, writeArticle } from './support/forms.js'
import { clearJsErrors, expectNoJsErrors, watchJsErrors } from './support/js-errors.js'

const board = { boardId: 'e2e-my-page', name: 'E2E マイページボード', visibility: '公開' }
const pastEvent = { name: 'e2e-my-page-past', title: 'E2E マイページ過去', ...pastEventPeriod() }
const futureEvent = { name: 'e2e-my-page-future', title: 'E2E マイページ未来', ...futureEventPeriod() }
const eventPath = (event) => `/boards/${board.boardId}/events/${event.name}`

// The my page opens on the "account settings" tab; the posts list lives in the other tab.
const openPostsTab = async (page) => {
  await page.goto('/users/edit')
  await page.locator('#my-page-posts-tab').click()
  await expect(page.locator('#my-page-posts-tab')).toHaveAttribute('aria-selected', 'true')
  await expect(page.locator('#my-page-posts')).toBeVisible()
}
const postsRow = (page, text) => page.locator('#my-page-posts li.my-posts-item', { hasText: text })

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
    await openPostsTab(page)
    const row = postsRow(page, 'E2E マイページ公開済み記事')
    await expect(row).toContainText('公開済み')
    await expect(row).toContainText(board.name)
    await expect(row).toContainText(pastEvent.title)
    await row.getByRole('link', { name: 'E2E マイページ公開済み記事' }).click()
    await expect(page).toHaveURL(/\/items\/\d+$/)
  })

  test('M-2 公開前の記事は編集画面へ、未執筆の枠は記事作成画面へ進める', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.bob)
    await openPostsTab(page)
    const scheduled = postsRow(page, 'E2E マイページ公開前記事')
    await expect(scheduled).toContainText('公開前')
    await scheduled.getByRole('link', { name: 'E2E マイページ公開前記事' }).click()
    await expect(page).toHaveURL(/\/items\/\d+\/edit$/)

    await openPostsTab(page)
    const unwritten = postsRow(page, futureEvent.title).filter({ hasText: '未執筆' })
    await expect(unwritten).toContainText(futureEvent.title)
    await unwritten.getByRole('link', { name: '記事を書く' }).click()
    await expect(page).toHaveURL(/\/items\/new/)
  })

  test('M-3 アカウント設定タブが既定で表示され、フォーム・テーマ・アカウント削除がある', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.bob)
    await page.goto('/users/edit')
    await expect(page.locator('#my-page-settings-tab')).toHaveAttribute('aria-selected', 'true')
    await expect(page.locator('#my-page-settings')).toBeVisible()
    await expect(page.locator('#my-page-posts')).toBeHidden()
    await expect(page.getByLabel('現在のパスワード')).toBeVisible()
    await expect(page.locator('#theme_dark')).toBeVisible()
    await expect(page.getByRole('button', { name: 'アカウント削除' })).toBeVisible()
  })

  test('M-4 保存に失敗すると、エラー付きでアカウント設定タブが選ばれて再表示される', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.bob)
    await page.goto('/users/edit')
    await page.getByLabel('名前').fill('e2e-bob-renamed')
    await page.getByLabel('現在のパスワード').fill('wrong-password')
    await page.locator('form[action="/users"] input[type=submit]').click()
    await expect(page.locator('.alert-danger')).toBeVisible()
    await expect(page.locator('#my-page-settings-tab')).toHaveAttribute('aria-selected', 'true')
    await expect(page.locator('#my-page-posts-tab')).toHaveAttribute('aria-selected', 'false')
  })

  test('M-5 21件以上の枠は「もっと見る」で続きが同じ画面に追加される', async ({ browser }) => {
    const { page } = await openAs(browser, accounts.bob)
    // bob already owns several slots in this run; 18 more push the total past one page (20).
    for (let day = 4; day <= 21; day += 1) await joinDay(page, eventPath(pastEvent), day)
    await openPostsTab(page)
    await expect(page.locator('#my-page-posts li.my-posts-item')).toHaveCount(20)
    await expect(postsRow(page, 'E2E マイページ公開済み記事')).toHaveCount(0)
    await page.getByRole('link', { name: 'もっと見る' }).click()
    await expect(postsRow(page, 'E2E マイページ公開済み記事')).toBeVisible()
    await expect.poll(() => page.locator('#my-page-posts li.my-posts-item').count()).toBeGreaterThan(20)
    await expect(page.getByRole('link', { name: 'もっと見る' })).toHaveCount(0)
    await expect(page).toHaveURL(/\/users\/edit$/)
  })
})
