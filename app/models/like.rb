# frozen_string_literal: true

# Represents a like on an article.
#
# Likes associate a user with an item they've liked.
#
# A user may like an item once. This is enforced on creation only and without a unique index, so
# duplicate rows that already exist stay valid and are neither deleted nor blocked from saving.
class Like < ApplicationRecord
  belongs_to :item
  belongs_to :user
  # A unique index is deliberately not added: existing duplicate rows would make the migration fail.
  validates :user_id, uniqueness: { scope: :item_id }, on: :create # rubocop:disable Rails/UniqueValidationWithoutIndex
end
