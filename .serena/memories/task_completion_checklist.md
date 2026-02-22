# Task Completion Checklist

After completing a task, run these checks:

1. **Format Ruby code**: `bundle exec rufo .` (if Ruby files changed)
2. **Run tests**: `bundle exec rspec spec`
3. **Check assets compile**: `bundle exec rake assets:precompile` (if frontend changed)
