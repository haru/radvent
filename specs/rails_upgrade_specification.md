# Rails アップグレード改造仕様書

## 1. 概要

| 項目 | 内容 |
|------|------|
| 対象アプリケーション | Radvent（Qiita風アドベントカレンダーWebアプリ） |
| 現行バージョン | Rails 7.0.2.2 / Ruby 3.1.4 |
| 目標バージョン | Rails 8.0.x（最新安定版） |
| Ruby要件 | Ruby 3.2以上（Rails 8の必須要件） |

## 2. アップグレード方針

Rails 7.0 → 8.0 は破壊的変更が多いため、**段階的アップグレード**を行う。

```
Phase 1: Rails 7.0 上での事前準備・負債解消
Phase 2: Rails 7.1 へのアップグレード
Phase 3: Rails 7.2 へのアップグレード
Phase 4: Rails 8.0 へのアップグレード
Phase 5: CI・Docker・インフラ更新
```

---

## 3. Phase 1: 事前準備（Rails 7.0 上での負債解消）

### 3.1 `config.load_defaults` の段階的更新

**現状:** `config.load_defaults 6.1`（Rails 7.0 で動作しているのに 6.1 のデフォルトのまま）

**対応:**
- `config/initializers/new_framework_defaults_7_0.rb` の全コメントアウトされた設定を一つずつ有効化・動作確認
- 全項目を有効化した後、`config.load_defaults 7.0` に変更
- `new_framework_defaults_7_0.rb` を削除

**影響を受ける設定:**
| 設定 | 変更内容 |
|------|----------|
| `ActiveSupport.utc_to_local_returns_utc_offset_times` | UTC変換の挙動変更 |
| `ActiveSupport::MessageEncryptor.use_authenticated_message_encryption` | 認証付き暗号化の有効化 |
| `ActiveRecord.verify_foreign_keys_for_fixtures` | フィクスチャの外部キー検証 |
| `ActionView::Helpers::FormTagHelper.default_enforce_utf8` | UTF-8エンフォースの無効化 |
| `ActionView::Helpers::UrlHelper.button_to_generates_button_tag` | button_toがbuttonタグを生成 |
| `ActiveRecord::Base.automatic_scope_inversing` | スコープの自動逆関連 |
| `ActiveRecord::Base.partial_inserts` | 部分INSERT（false）に変更 |
| `ActionController::Base.raise_on_open_redirects` | オープンリダイレクトで例外 |

### 3.2 モデルの `ApplicationRecord` 継承への移行

**現状:** 全モデルが `ActiveRecord::Base` を直接継承

**対応:**
以下の全モデルの継承元を `ApplicationRecord` に変更する。

| ファイル | 変更内容 |
|----------|----------|
| `app/models/user.rb` | `< ActiveRecord::Base` → `< ApplicationRecord` |
| `app/models/item.rb` | 同上 |
| `app/models/event.rb` | 同上 |
| `app/models/comment.rb` | 同上 |
| `app/models/like.rb` | 同上 |
| `app/models/attachment.rb` | 同上 |
| `app/models/advent_calendar_item.rb` | 同上 |

### 3.3 `factory_girl` 参照の修正

**対象:** `config/application.rb`

```ruby
# 修正前
g.fixture_replacement :factory_girl
# 修正後
g.fixture_replacement :factory_bot, dir: 'spec/factories'
```

### 3.4 `secrets.yml` から `credentials` への移行

**現状:** `config/secrets.yml.example` + Rakeタスクでコピーするレガシー方式（Rails 4時代）

**対応:**
- `rails credentials:edit` で暗号化済みcredentialsファイルを作成
- 既存の `secrets.yml` の内容を移行
- `lib/tasks/radvent.rake` から `secrets.yml` のコピー処理を削除

---

## 4. Phase 2: Rails 7.1 へのアップグレード

### 4.1 Gemfile の変更

```ruby
# 変更
gem 'rails', '~> 7.1.0'
gem 'puma', '~> 6.0'          # Puma 6 対応
gem 'sqlite3', '>= 1.4'       # バージョン制約緩和

# 削除候補
gem 'spring'                    # Rails 7.1でデフォルトから除外
```

### 4.2 設定ファイルの更新

#### `config/environments/development.rb`
```ruby
# 変更前
config.cache_classes = false
# 変更後
config.enable_reloading = true
```

#### `config/environments/production.rb`
```ruby
# 変更前
config.cache_classes = true
# 変更後
config.enable_reloading = false
```

#### `config/environments/test.rb`
```ruby
# 変更前
config.cache_classes = true
config.action_dispatch.show_exceptions = false
# 変更後
config.enable_reloading = false
config.action_dispatch.show_exceptions = :none
```

#### 非推奨APIの更新
```ruby
# 変更前（development.rb / test.rb）
config.active_support.deprecation = :log
config.active_support.disallowed_deprecation = :raise
config.active_support.disallowed_deprecation_warnings = []
# 変更後
config.active_support.report_deprecations = true
```

### 4.3 `new_framework_defaults_7_1.rb` の対応

Rails 7.1 アップグレード時に生成される新デフォルト設定ファイルを順次有効化し、`config.load_defaults 7.1` へ移行する。

---

## 5. Phase 3: Rails 7.2 へのアップグレード

### 5.1 Gemfile の変更

```ruby
gem 'rails', '~> 7.2.0'
```

### 5.2 `new_framework_defaults_7_2.rb` の対応

同様に順次有効化し、`config.load_defaults 7.2` へ移行する。

---

## 6. Phase 4: Rails 8.0 へのアップグレード

### 6.1 Webpacker → jsbundling-rails への移行（最大の作業）

**現状:** Webpacker 5.4.3 を使用。Rails 8 では完全に非対応。

**移行方針:** `jsbundling-rails` + `esbuild` に移行する。

#### 6.1.1 削除対象

| 対象 | ファイル/ディレクトリ |
|------|----------------------|
| Gem | `webpacker` を Gemfile から削除 |
| 設定 | `config/webpacker.yml` |
| bin スクリプト | `bin/webpack`, `bin/webpack-dev-server` |
| npm パッケージ | `@rails/webpacker` を `package.json` から削除 |

#### 6.1.2 新規導入

```ruby
# Gemfile に追加
gem 'jsbundling-rails'
gem 'cssbundling-rails'  # sass-rails の置き換え
```

#### 6.1.3 JavaScript エントリーポイントの移行

| 移行前（Webpacker） | 移行後（esbuild） |
|---------------------|-------------------|
| `app/javascript/packs/application.js` | `app/javascript/application.js` |
| `app/javascript/packs/common.js` | `app/javascript/common.js` |
| `app/javascript/packs/events.js` | `app/javascript/events.js` |
| `app/javascript/packs/items.js` | `app/javascript/items.js` |
| `app/javascript/packs/likes.js` | `app/javascript/likes.js` |
| `app/javascript/packs/mdb.js` | `app/javascript/mdb.js` |
| `app/javascript/packs/users.js` | `app/javascript/users.js` |

#### 6.1.4 ビューヘルパーの変更

```haml
-# 変更前
= stylesheet_pack_tag 'application', 'data-turbolinks-track': 'reload'
= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload'

-# 変更後
= stylesheet_link_tag 'application', 'data-turbo-track': 'reload'
= javascript_include_tag 'application', 'data-turbo-track': 'reload', defer: true
```

### 6.2 Turbolinks → Turbo（Hotwire）への移行

**現状:** Turbolinks 5.2.1 を使用

#### 6.2.1 Gem/パッケージの変更

```ruby
# Gemfile
# 削除
gem 'turbolinks', '~> 5'
# 追加
gem 'turbo-rails'
```

```bash
# npm
yarn remove turbolinks
yarn add @hotwired/turbo-rails
```

#### 6.2.2 JavaScript の変更

```javascript
// 変更前
import Turbolinks from "turbolinks"
Turbolinks.start()

// 変更後
import "@hotwired/turbo-rails"
```

#### 6.2.3 イベント名の置換

全 JavaScript ファイルで以下の置換を行う。

| 変更前 | 変更後 | 対象ファイル |
|--------|--------|-------------|
| `turbolinks:load` | `turbo:load` | `common.js`, `events.js`, `items.js`, `users.js` |
| `turbolinks:render` | `turbo:render` | `items.js` |

#### 6.2.4 ビューの `data-turbolinks-track` 属性の置換

全 HAML テンプレートで `data-turbolinks-track` → `data-turbo-track` に変更。

### 6.3 Rails UJS の移行

**現状:** `remote: true` および `method: :delete` で Rails UJS に依存

**対応:**

| パターン | 変更前 | 変更後 |
|----------|--------|--------|
| AJAX フォーム | `form_for ..., remote: true` | Turbo Frame / Turbo Stream に変更 |
| DELETE リンク | `link_to ..., method: :delete` | `button_to ..., method: :delete` に変更 |

**対象ビュー:**
- `app/views/items/_form_attachment.html.haml` （`remote: true`）
- `app/views/items/_like.html.haml` （`remote: true`）
- `app/views/shared/_header.html.haml` （`method: :delete` ログアウト）
- `app/views/comments/_comment.html.haml` （`method: :delete`）

### 6.4 Gemfile の変更（Rails 8.0）

```ruby
# 変更
gem 'rails', '~> 8.0.0'
gem 'sqlite3', '>= 2.0'       # Rails 8 要件
gem 'puma', '>= 6.0'

# 削除
gem 'webpacker', '~> 5.0'
gem 'turbolinks', '~> 5'
gem 'sass-rails', '>= 6'
gem 'spring'
gem 'byebug'                   # Ruby 3.2+ は debug gem を使用

# 追加
gem 'jsbundling-rails'
gem 'cssbundling-rails'
gem 'turbo-rails'
gem 'stimulus-rails'           # 必要に応じて
gem 'debug', group: [:development, :test]  # byebug の代替

# 更新が必要な Gem
gem 'devise', '~> 4.9'        # Rails 8 対応版
gem 'haml-rails', '~> 2.1'    # Rails 8 対応確認
gem 'carrierwave', '~> 3.0'   # Rails 8 対応版
gem 'bootsnap', '>= 1.18'
```

### 6.5 設定ファイルの最終更新

```ruby
# config/application.rb
config.load_defaults 8.0
```

### 6.6 削除対象ファイル

| ファイル | 理由 |
|----------|------|
| `config/webpacker.yml` | Webpacker 廃止 |
| `bin/webpack` | Webpacker 廃止 |
| `bin/webpack-dev-server` | Webpacker 廃止 |
| `bin/spring` | Spring 廃止 |
| `config/spring.rb` | Spring 廃止 |
| `config/secrets.yml.example` | credentials に移行済み |
| `config/initializers/new_framework_defaults_7_0.rb` | load_defaults 更新済み |
| `app/assets/javascripts/application.js` | レガシー Sprockets マニフェスト（未使用） |

---

## 7. Phase 5: CI・Docker・インフラ更新

### 7.1 CI（GitHub Actions）の更新

**対象:** `.github/workflows/build.yml`

| 項目 | 変更前 | 変更後 |
|------|--------|--------|
| Ruby バージョン | 3.0, 3.1 | 3.2, 3.3 |
| MySQL バージョン | 5.7（EOL） | 8.0 |
| Node.js バージョン | 14.x（EOL） | 20.x |
| `actions/checkout` | v2 | v4 |
| `codecov/codecov-action` | v2 | v4 |

### 7.2 Docker の更新

**対象:** `docker-compose.yml`, `.devcontainer/docker-compose.yml`, `Dockerfile`

- ベースイメージを `ruby:3.3` に更新
- Node.js 20.x のインストール
- `build-scripts/install.sh` のNode.jsバージョン更新

### 7.3 Gemfile の Ruby バージョン制約

```ruby
# 変更前
ruby '>= 3.0.0'
# 変更後
ruby '>= 3.2.0'
```

---

## 8. テスト計画

各フェーズで以下を実施する。

### 8.1 自動テスト

```bash
bundle exec rspec spec              # 全テスト実行
bundle exec rspec spec/models/      # モデルスペック
bundle exec rspec spec/controllers/ # コントローラスペック
```

### 8.2 手動確認項目

| # | 確認項目 | 確認方法 |
|---|----------|----------|
| 1 | ユーザー登録・ログイン・ログアウト | Deviseの全フローを手動確認 |
| 2 | イベント作成・編集・削除 | CRUD操作の確認 |
| 3 | 記事作成・Markdownプレビュー | Marked.js の動作確認 |
| 4 | いいね機能（非同期） | Turbo Stream への移行後にAJAX動作確認 |
| 5 | コメント投稿・削除 | 非同期動作の確認 |
| 6 | ファイルアップロード | CarrierWave の動作確認 |
| 7 | アドベントカレンダー表示 | 日付マッピングの正常動作 |
| 8 | 管理者機能 | ユーザー管理画面の確認 |
| 9 | レスポンシブ表示 | Bootstrap/MDB の動作確認 |
| 10 | 日本語/英語ロケール切替 | i18n の動作確認 |

### 8.3 非互換テスト

```bash
# 非推奨警告の確認
RAILS_ENV=test bundle exec rspec 2>&1 | grep "DEPRECATION"
```

---

## 9. リスクと対策

| リスク | 影響度 | 対策 |
|--------|--------|------|
| Webpacker移行でJS動作不良 | 高 | esbuild設定を段階的にテスト。ビルド出力を差分確認 |
| Turbolinks→Turbo移行でAJAX不具合 | 高 | `remote: true` のフォームを個別にTurbo Stream化しテスト |
| Devise の Rails 8 非互換 | 中 | Devise 4.9+ へ先行アップデートし互換性確認 |
| marked-rails の互換性 | 中 | npm パッケージ版の marked.js への移行を検討 |
| CarrierWave の互換性 | 中 | CarrierWave 3.0 へのアップデート。ActiveStorage移行は見送り |
| haml / haml-rails の互換性 | 中 | HAML 6.x への移行テスト。テンプレート構文の非互換確認 |
| データベースマイグレーション | 低 | 既存マイグレーションの動作確認。新形式への書き換えは不要 |

---

## 10. 作業スケジュール（目安）

| Phase | 作業内容 | 見積もり |
|-------|----------|----------|
| Phase 1 | 事前準備・負債解消 | 小 |
| Phase 2 | Rails 7.1 アップグレード | 小〜中 |
| Phase 3 | Rails 7.2 アップグレード | 小 |
| Phase 4 | Rails 8.0 アップグレード（Webpacker/Turbo移行含む） | 大 |
| Phase 5 | CI・Docker更新 | 小 |

**注記:** Phase 4 が最も工数が大きい。特にWebpacker→jsbundling-rails移行とTurbolinks→Turbo移行は、フロントエンド全体に影響する。

---

## 11. 参考資料

- [Rails アップグレードガイド（公式）](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html)
- [Rails 8.0 リリースノート](https://guides.rubyonrails.org/8_0_release_notes.html)
- [Webpacker からの移行ガイド](https://github.com/rails/jsbundling-rails/blob/main/docs/switch_from_webpacker.md)
- [Turbo ハンドブック](https://turbo.hotwired.dev/handbook/introduction)
