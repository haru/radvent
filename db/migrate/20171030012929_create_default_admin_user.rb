# frozen_string_literal: true

# Seeding the default admin user is `db/seeds.rb`'s job (`User.none?` guard),
# not this migration's: a migration that creates records through an
# ActiveRecord model couples it to that model's schema forever, even as the
# model gains columns (e.g. the `theme` enum) that don't exist yet at this
# point in migration history. This migration is kept only so its already
# applied version is not re-run on existing databases.
class CreateDefaultAdminUser < ActiveRecord::Migration[4.2]
  def up; end

  def down; end
end
