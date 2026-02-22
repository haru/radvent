# Copilot Instructions

Radvent は Qiita風アドベントカレンダーアプリ。Ruby on Rails 8.1 / Ruby 3.0+。

## Build & Test

```bash
bundle install && yarn install
bundle exec rake radvent:generate_default_settings
bundle exec rake db:create db:migrate
bundle exec rails s

# テスト
bundle exec rspec spec                          # 全テスト
bundle exec rspec spec/models/user_spec.rb:42   # 行指定
```

## Architecture

```
Event ──< AdventCalendarItem >── User
               │
               └──1 Item ──< Comment
                      └──< Like >── User
```

- `AdventCalendarItem` はカレンダーの「枠」（日付×イベント×ユーザー）。`date` カラムは **Integer**（1〜31）であり Date 型ではない
- `Item` が実記事。`belongs_to :advent_calendar_item`（unique）
- `Comment` に `user_id` カラムは**ない**。`user_name` 文字列のみ保存
- Event の show ルートは名前ベース → `show_event_path(event.name)`（`event_path(event)` は誤り）

## Code Style

- ビューはすべて **HAML**（`.html.haml`）。ERB は使わない
- Ruby は シングルクォート優先（rufo で整形）
- i18n: デフォルトロケール `:ja`、タイムゾーン `Tokyo`
- レイアウト: 管理画面は `layouts/admin`、公開側は `layouts/application`
  - `EventsController` は `layout 'admin'` だが `show` のみ `render layout: 'application'`

## Project Conventions

**権限チェック:**
```ruby
before_action :authenticate_user!
admin_user!              # ApplicationController: 管理者以外は render_403
render_404 / render_403  # ApplicationController のヘルパー
current_user.admin?      # 管理者判定
```

**Eventのルーティング:**
```ruby
get 'events/:name' => 'events#show', as: :show_event
# Items にはpreview（collection + member）とlikesが入れ子
```

**HAMLの典型パターン:**
```haml
- content_for(:jumbotron) do
  %div.jumbotron= @event.title
= render "partial", item: @item
= t("views.events.show.some_key")
```

## Testing

- RSpec + FactoryBot（`create/build` を直接呼べる）
- Devise: `sign_in @user`（`Devise::Test::ControllerHelpers` 自動include）
- 日付モック: `allow(Time.zone).to receive(:today).and_return(Date.new(2015, 12, 2))`
- テスト冒頭で `Model.destroy_all` を呼ぶ慣習あり

```ruby
RSpec.describe ItemsController, type: :controller do
  before do
    @user = create(:user)
    sign_in @user
  end
end
```

## Key Files

| 目的 | パス |
|---|---|
| モデル | `app/models/` — `advent_calendar_item.rb`, `item.rb`, `event.rb`, `user.rb` |
| コントローラー | `app/controllers/application_controller.rb` |
| ルーティング | `config/routes.rb` |
| スキーマ | `db/schema.rb` |
| ファクトリ | `spec/factories/` |
| i18n | `config/locales/` |
