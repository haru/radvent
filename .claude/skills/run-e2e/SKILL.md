---
name: run-e2e
description: Radvent の Playwright E2E テスト（yarn e2e）を実行し、結果を報告・失敗を切り分けるスキル。「e2eを実行して」「E2Eテスト回して」「画面操作のテストを通して」「ブラウザテストで確認」「Playwrightテストを走らせて」など、E2E／エンドツーエンド／ブラウザ自動テストの実行や失敗調査を求められたら、明示的にスキル名が出なくても必ずこのスキルを使うこと。rspec など単体テストの実行や、MCP で画面を手動操作する用途（playwright-screen-access）には使わない。
---

# E2E テストを実行する

Radvent の E2E は Playwright + 専用 Rails 環境 (`e2e`, port 4500)。詳細は `docs/e2e-testing.md` と ADR-0013。
CI にも rspec にも含まれないので、必要なときにオンデマンドで実行する。

## 手順

1. **事前確認**（両方 1 コマンドで済ませる）
   ```bash
   ss -ltn | grep ':4500 ' && echo "IN USE" || echo "free"
   ls ~/.cache/ms-playwright   # chromium-* と chromium_headless_shell-* があること
   ```
   - 4500 が使用中なら実行しない。原因プロセスをユーザーに伝える（勝手に kill しない）。
   - Chromium が無ければ `yarn playwright install chromium`（システムライブラリ不足なら `--with-deps`）。ダウンロードを伴うのでユーザーに一言断る。

2. **実行**（`yarn e2e` 1 コマンド。サーバー起動・DB リセット・停止は Playwright が行う）
   ```bash
   yarn e2e 2>&1 | tail -40
   ```
   - 所要時間は約 40 秒（初回のアセットビルドで伸びることがある）。タイムアウトは長め（600000ms）にする。
   - 出力の大半は `[WebServer]` の Rails ログ。結果は末尾の `N passed` / `N failed` と `✓` / `✘` 行を見る。`tail` で十分。

3. **報告**: 通過数・失敗数・所要時間を簡潔に伝える。失敗があれば下の切り分けに進む。

## データの安全性

E2E は `db/radvent_e2e.sqlite3`、`tmp/e2e/`、`log/e2e.log`、`public/e2e-assets` を毎回作り直す。開発/テスト DB・`db/schema.rb`・`public/assets`・`storage/` には触れない。したがって実行自体は安全で、追加の承認は不要。逆に、E2E のために dev DB を `db:reset` するなどの操作は絶対にしない。

## 失敗の切り分け

| 症状 | 見るもの |
|------|----------|
| シナリオ失敗 (`AS 3-1 ...` のステップ名) | 期待値と実際値。`test-results/` のスクリーンショット・trace |
| `already used` | ポート 4500 が使用中 |
| `webServer was not able to start` | 出力中のアセットビルド/DB リセット/起動エラー、`log/e2e.log` |
| 300 秒タイムアウト | 出力中の Rails ログ |

- シナリオは `test.describe.serial` で順に依存するため、1 つ失敗すると後続は "did not run"。**最初の失敗だけ**が本物の原因。
- `--grep` で単一シナリオだけ実行することはできない（前のシナリオのデータとログイン状態に依存）。
- リトライは無い。flaky を疑う前に、同じ失敗が再現するかもう一度 `yarn e2e` で確認する。
- 4xx/5xx に対するコンソール行は失敗扱いにならない。ログに `RoutingError` があっても、テストが通っていれば失敗ではない（ただし気になる場合は別途報告する）。
- 未捕捉のブラウザエラー (`pageerror`, `console.error`) はテスト失敗になる。

## 失敗後の追加調査

```bash
yarn playwright show-report      # HTML レポート（ブラウザ表示が必要）
ls test-results/                 # 失敗テストのスクリーンショット・trace
tail -100 log/e2e.log            # Rails 側のログ
```
`--headed` はコンテナに表示先が無いと動かないので、devcontainer では基本使わない。

## 失敗を直すとき

プロジェクトの規約 (AGENTS.md) に従う: 原因を特定してから最小限の修正を行い、エラーを握りつぶすような回避（待機の延長だけで済ませる、例外の無視など）をしない。コミットはユーザーの許可が出るまでしない。lint (`sh build-scripts/lint.sh`) は E2E の JS も対象。
