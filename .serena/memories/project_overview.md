# Radvent - Project Overview

## Purpose
Qiita-style Advent Calendar web application (Japanese-focused). Users can create events, publish markdown articles on specific calendar dates, and interact via likes and comments.

## Tech Stack
- **Backend**: Ruby (>= 3.0) / Rails 7.0, Puma, Devise (auth)
- **Frontend**: Webpacker 5 (webpack 4), HAML templates, SCSS, Bootstrap 5 (mdb-ui-kit), jQuery
- **Markdown**: Marked.js with highlight.js
- **File uploads**: CarrierWave
- **Database**: SQLite3 (dev default), MySQL 5.7+, or PostgreSQL
- **Testing**: RSpec, FactoryBot, Capybara

## Key Models
- User (Devise auth, admin role)
- Event (advent calendar with start/end dates)
- Item (markdown article, belongs to user/event)
- AdventCalendarItem (maps item to calendar day)
- Like / Comment (user interactions)
- Attachment (CarrierWave uploads)

## Codebase Structure
```
app/
  controllers/    # Rails controllers
  models/         # ActiveRecord models
  views/          # HAML templates
  javascript/     # Webpacker source (packs/, channels/, stylesheets/)
  assets/         # Legacy Sprockets assets
  uploaders/      # CarrierWave uploaders
config/
  webpack/        # Webpack configuration
  webpacker.yml   # Webpacker settings
spec/             # RSpec tests
```

## Routing
- Events: `/events/:name` (name-based, not ID)
- Items: nested likes resource, preview member route
- Root: `welcome#index`

## Configuration
- Timezone: Tokyo
- Default locale: Japanese (:ja)
- App settings via `rake radvent:generate_default_settings`
