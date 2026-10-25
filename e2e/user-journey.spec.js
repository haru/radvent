import { test, expect } from '@playwright/test'
import { accounts, login, logout, openAs, rememberLogin } from './support/accounts.js'
import { fillMarkdown } from './support/editor.js'
import { futureEventPeriod, pastEventPeriod } from './support/dates.js'

async function register(page, account) {
  await page.goto('/users/sign_up')
  await page.getByLabel('メールアドレス').fill(account.email)
  await page.getByLabel('名前').fill(account.name)
  await page.getByLabel('パスワード', { exact: true }).fill(account.password)
  await page.getByLabel('確認用パスワード').fill(account.password)
  await page.getByRole('button', { name: 'アカウント登録' }).click()
  await expect(page.locator('#navTopMenu .dropdown-toggle')).toHaveText(account.name)
}

const boardId = 'e2e-board'
const boardName = 'E2E ボード'
const boardNameEdited = 'E2E ボード(編集後)'
const pastEvent = { name: 'e2e-past', title: 'E2E 過去のカレンダー', ...pastEventPeriod() }
const futureEvent = { name: 'e2e-future', title: 'E2E 未来のカレンダー', ...futureEventPeriod() }
const pastEventPath = `/boards/${boardId}/events/${pastEvent.name}`
const futureEventPath = `/boards/${boardId}/events/${futureEvent.name}`

const articleBody = '# E2E 見出し\n\nE2E 本文の **強調** です。'
const articleTitle = 'E2E 記事'
const articleTitleEdited = 'E2E 記事(編集後)'

// The calendar cell of the given day of the event. Cells of neighbouring months show the same
// day numbers but carry neither a join button nor an author.
function dayCell(page, day) {
  return page
    .locator('td', { has: page.locator('p.advent-calendar-date', { hasText: new RegExp(`^\\s*${day}\\s*$`) }) })
    .filter({ has: page.locator('.advent-calendar-author, .advent-calendar-join') })
}

// Joins the calendar on the given day; ends on that slot's page.
async function joinDay(page, eventPath, day) {
  await page.goto(eventPath)
  await dayCell(page, day).getByRole('link', { name: '参加登録' }).click()
  await page.getByRole('button', { name: '登録する' }).click()
  await expect(page.getByRole('heading', { name: 'AdventCalendar情報' })).toBeVisible()
}

// From a slot page, writes and saves an article; ends back on the slot page.
async function writeArticle(page, title, body) {
  await page.getByRole('link', { name: '記事を登録する' }).click()
  await page.getByLabel('タイトル').fill(title)
  await fillMarkdown(page, body)
  await page.getByRole('button', { name: '登録する' }).click()
  await expect(page.getByText('記事が登録されています')).toBeVisible()
}

async function createEvent(page, event) {
  await page.getByRole('link', { name: 'イベントを作成' }).click()
  await page.getByLabel('名', { exact: true }).fill(event.name)
  await page.getByLabel('タイトル').fill(event.title)
  await page.getByLabel('開始日').fill(event.start)
  await page.getByLabel('終了日').fill(event.end)
  await page.getByRole('button', { name: '登録する' }).click()
}

test.describe.serial('利用者の一連の操作', () => {
  // Path of the published article (set by US4, used by US5).
  let itemPath

  test('US2 初回ログインからユーザー作成まで', async ({ page }) => {
    await test.step('AS 2-1 初期管理者でログインし、ユーザー一覧を開ける', async () => {
      await login(page, accounts.admin)
      await page.goto('/users')
      await expect(page.getByRole('cell', { name: accounts.admin.email })).toBeVisible()
    })

    await test.step('AS 2-2 新規登録すると、そのユーザーでログインした状態になる', async () => {
      await logout(page)
      await register(page, accounts.alice)
      await rememberLogin(page, 'alice')
      await logout(page)
      await register(page, accounts.bob)
      await rememberLogin(page, 'bob')
    })

    await test.step('AS 2-3 ログアウトして、同じ認証情報で再びログインできる', async () => {
      await logout(page)
      await login(page, accounts.alice)
    })

    await test.step('AS 2-4 誤ったパスワードではログインできない', async () => {
      await logout(page)
      await page.goto('/users/sign_in')
      await page.getByLabel('メールアドレス').fill(accounts.alice.email)
      await page.getByLabel('パスワード', { exact: true }).fill('wrong-password')
      await page.getByRole('button', { name: 'ログイン' }).click()
      await expect(page.getByText('メールアドレスかパスワードが違うか、一時的にログインが制限されています。')).toBeVisible()
      await expect(page).toHaveURL(/\/users\/sign_in$/)
    })

    await test.step('AS 2-5 管理者のユーザー一覧に、登録したユーザーが出る', async () => {
      await login(page, accounts.admin)
      await page.goto('/users')
      await expect(page.getByRole('cell', { name: accounts.alice.email })).toBeVisible()
      await expect(page.getByRole('cell', { name: accounts.bob.email })).toBeVisible()
    })
  })

  test('US3 ボードとイベントの作成', async ({ browser }) => {
    const { context, page } = await openAs(browser, 'alice')

    await test.step('AS 3-1 ボードを作ると、ボードの画面と一覧に出る', async () => {
      await page.goto('/boards')
      await page.getByRole('link', { name: '新しいボードを作成' }).click()
      await page.getByLabel('ボードID').fill(boardId)
      await page.getByLabel('ボード名').fill(boardName)
      await page.getByRole('radio', { name: /^公開 —/ }).check()
      await page.getByRole('button', { name: '登録する' }).click()
      await expect(page.getByRole('heading', { name: boardName })).toBeVisible()
      await page.goto('/boards')
      await expect(page.getByRole('cell', { name: boardName, exact: true })).toBeVisible()
    })

    await test.step('AS 3-2 ボードを編集すると、変更が反映される', async () => {
      await page.getByRole('link', { name: 'ボード設定' }).click()
      await page.getByLabel('ボード名').fill(boardNameEdited)
      await page.getByRole('button', { name: '更新する' }).click()
      await expect(page.getByRole('heading', { name: boardNameEdited })).toBeVisible()
    })

    await test.step('AS 3-3 イベントを作ると、ボードに出て、期間分のカレンダーが出る', async () => {
      await page.goto(`/boards/${boardId}`)
      await createEvent(page, pastEvent)
      await page.getByRole('link', { name: 'イベントを作成' }).waitFor()
      await createEvent(page, futureEvent)
      await expect(page.getByRole('heading', { name: pastEvent.title })).toBeVisible()
      await expect(page.getByRole('heading', { name: futureEvent.title })).toBeVisible()
      await page.goto(pastEventPath)
      await expect(page.getByRole('link', { name: '参加登録' })).toHaveCount(pastEvent.lastDay)
    })

    await test.step('AS 3-4 イベントを編集すると、変更が反映される', async () => {
      await page.goto(`${pastEventPath}/edit`)
      await page.getByLabel('説明').fill('E2E 編集後の説明')
      await page.getByRole('button', { name: '更新する' }).click()
      await expect(page.getByText('E2E 編集後の説明')).toBeVisible()
    })

    await test.step('AS 3-5 ボードにメンバーを追加すると、メンバー一覧に出る', async () => {
      await page.goto(`/boards/${boardId}/edit`)
      await page.getByRole('link', { name: 'メンバー管理' }).click()
      await page.getByPlaceholder('ユーザー名またはメールアドレス').fill(accounts.bob.name)
      await page.getByRole('button', { name: 'メンバーを追加' }).click()
      await expect(page.getByRole('cell', { name: accounts.bob.name, exact: true })).toBeVisible()
    })

    await context.close()
  })

  test('US4 記事の登録・編集・削除', async ({ browser }) => {
    const { context, page } = await openAs(browser, 'alice')
    let deletableSlotPath

    await test.step('AS 4-1 空いている日に参加登録すると、枠に名前が出る', async () => {
      await joinDay(page, pastEventPath, 1)
      await joinDay(page, pastEventPath, 2)
      await page.goto(pastEventPath)
      await expect(dayCell(page, 1)).toContainText(accounts.alice.name)
      await expect(dayCell(page, 2)).toContainText(accounts.alice.name)
    })

    await test.step('AS 4-3 保存する前に、プレビューで整形された本文を確認できる', async () => {
      await dayCell(page, 1).getByRole('link', { name: '編集' }).click()
      await page.getByRole('link', { name: '記事を登録する' }).click()
      await page.getByLabel('タイトル').fill(articleTitle)
      await fillMarkdown(page, articleBody)
      const popupPromise = page.waitForEvent('popup')
      await page.getByRole('button', { name: 'プレビュー' }).click()
      const preview = await popupPromise
      await expect(preview.locator('#item-show h1')).toHaveText('E2E 見出し')
      await expect(preview.locator('#item-show strong')).toHaveText('強調')
      await preview.close()
    })

    await test.step('AS 4-2 記事を保存すると、整形された内容が記事の画面に出る', async () => {
      await page.getByRole('button', { name: '登録する' }).click()
      await page.getByRole('link', { name: '投稿記事を表示する' }).click()
      await expect(page).toHaveURL(/\/items\/\d+$/)
      itemPath = new URL(page.url()).pathname
      await expect(page.locator('.item-show-header-title')).toHaveText(articleTitle)
      await expect(page.locator('#item-show h1')).toHaveText('E2E 見出し')
      await expect(page.locator('#item-show strong')).toHaveText('強調')
    })

    await test.step('AS 4-4 記事を編集すると、変更後の内容が出る', async () => {
      await page.getByRole('link', { name: '記事を編集する' }).click()
      await page.getByLabel('タイトル').fill(articleTitleEdited)
      await page.getByRole('button', { name: '登録する' }).click()
      await page.getByRole('link', { name: '投稿記事を表示する' }).click()
      await expect(page.locator('.item-show-header-title')).toHaveText(articleTitleEdited)
    })

    // Items have no required field (an empty title is shown as 無題), so there is no input error to
    // provoke on an article; this step pins that behaviour down on the article that AS 4-5 deletes.
    await test.step('AS 4-6 タイトルを空にしても保存でき、無題の記事になる(記事に必須項目はない)', async () => {
      await page.goto(pastEventPath)
      await dayCell(page, 2).getByRole('link', { name: '編集' }).click()
      await writeArticle(page, 'E2E 削除する記事', 'E2E 削除される本文')
      deletableSlotPath = new URL(page.url()).pathname
      await page.getByRole('link', { name: '投稿記事を表示する' }).click()
      await page.getByRole('link', { name: '記事を編集する' }).click()
      await page.getByLabel('タイトル').fill('')
      await page.getByRole('button', { name: '登録する' }).click()
      await expect(page.locator('.alert-danger')).toHaveCount(0)
      await page.getByRole('link', { name: '投稿記事を表示する' }).click()
      await expect(page.locator('.item-show-header-title')).toHaveText('無題')
    })

    await test.step('AS 4-5 枠を削除すると、その日は再び空きになる', async () => {
      await page.goto(deletableSlotPath)
      page.once('dialog', (dialog) => dialog.accept())
      await page.getByRole('button', { name: '削除' }).click()
      await expect(page).toHaveURL(new RegExp(`${pastEventPath}$`))
      await expect(dayCell(page, 2).getByRole('link', { name: '参加登録' })).toBeVisible()
    })

    await test.step('AS 4-7 十分先の日付の記事は、作者以外には見えない', async () => {
      await joinDay(page, futureEventPath, 1)
      await writeArticle(page, 'E2E 未来の記事', 'E2E 未来の本文')
      const futureItemPath = new URL(
        await page.getByRole('link', { name: '投稿記事を編集する' }).getAttribute('href'),
        page.url()
      ).pathname.replace('/edit', '')

      const bob = await openAs(browser, 'bob')
      const visitor = await browser.newContext({ baseURL: 'http://127.0.0.1:4500', locale: 'ja-JP' })
      const visitorPage = await visitor.newPage()
      for (const viewer of [bob.page, visitorPage]) {
        await viewer.goto(futureItemPath)
        await expect(viewer).toHaveURL(/\/$/)
        await expect(viewer.getByText('E2E 未来の記事')).toHaveCount(0)
        await expect(viewer.getByText('E2E 未来の本文')).toHaveCount(0)
      }
      await bob.context.close()
      await visitor.close()

      await page.goto(`${futureItemPath}/edit`)
      await expect(page.locator('.CodeMirror')).toContainText('E2E 未来の本文')
      const popupPromise = page.waitForEvent('popup')
      await page.getByRole('button', { name: 'プレビュー' }).click()
      const preview = await popupPromise
      await expect(preview.locator('#item-show')).toContainText('E2E 未来の本文')
      await preview.close()
    })

    await context.close()
  })

  test('US5 コメントといいね', async ({ browser }) => {
    const likeCount = (page) => page.locator('#like-button')
    // Font Awesome swaps <i> for an <svg>; the prefix tells solid (liked) from regular (not liked).
    const heart = (page) => page.locator('#like-button svg')

    await test.step('AS 5-1 コメントを投稿すると、ページを読み直さずに出る', async () => {
      const visitor = await browser.newContext({ baseURL: 'http://127.0.0.1:4500', locale: 'ja-JP' })
      const page = await visitor.newPage()
      await page.goto(itemPath)
      await page.evaluate(() => { window.__e2eMarker = true })
      await page.getByLabel('お名前を入力してください').fill('E2E 読者')
      await page.getByLabel('コメントを入力してください').fill('E2E コメント')
      await page.getByRole('button', { name: '投稿する' }).click()
      await expect(page.locator('#comments_list')).toContainText('E2E 読者')
      await expect(page.locator('#comments_list')).toContainText('E2E コメント')
      expect(await page.evaluate(() => window.__e2eMarker)).toBe(true)
      await visitor.close()
    })

    await test.step('AS 5-2 削除権限を持つユーザーがコメントを削除すると、消える', async () => {
      const { context, page } = await openAs(browser, 'alice')
      await page.goto(itemPath)
      await expect(page.locator('#comments_list')).toContainText('E2E コメント')
      page.once('dialog', (dialog) => dialog.accept())
      await page.locator('#comments_list').getByRole('button', { name: '削除' }).click()
      await expect(page.locator('#comments_list')).not.toContainText('E2E コメント')
      await context.close()
    })

    const bob = await openAs(browser, 'bob')

    await test.step('AS 5-3 いいねを押すと、数が 1 増え、いいね済みになる', async () => {
      await bob.page.goto(itemPath)
      await expect(likeCount(bob.page)).toHaveText('0')
      await expect(heart(bob.page)).toHaveAttribute('data-prefix', 'far')
      await likeCount(bob.page).click()
      await expect(likeCount(bob.page)).toHaveText('1')
      await expect(heart(bob.page)).toHaveAttribute('data-prefix', 'fas')
    })

    await test.step('AS 5-4 もう一度押すと、数が 1 減り、元に戻る', async () => {
      await likeCount(bob.page).click()
      await expect(likeCount(bob.page)).toHaveText('0')
      await expect(heart(bob.page)).toHaveAttribute('data-prefix', 'far')
    })

    await test.step('AS 5-5 別々のユーザーがいいねすると、人数分になる', async () => {
      await likeCount(bob.page).click()
      await expect(likeCount(bob.page)).toHaveText('1')
      const alice = await openAs(browser, 'alice')
      await alice.page.goto(itemPath)
      await likeCount(alice.page).click()
      await expect(likeCount(alice.page)).toHaveText('2')
      await alice.page.goto(itemPath)
      await expect(likeCount(alice.page)).toHaveText('2')
      await alice.context.close()
    })

    await bob.context.close()
  })
})
