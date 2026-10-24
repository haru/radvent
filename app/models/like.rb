# frozen_string_literal: true

# Represents a like on an article.
#
# Likes associate a user with an item they've liked.
#
# A user may like an item once. This is enforced by a validation on creation only and without a
# unique index, so the validation neither deletes nor blocks saving of duplicate rows that already
# exist, and two concurrent creates can still insert a duplicate. Readers therefore count distinct
# users (Item#like_count, Item#liked_users). Adding the index needs a migration that first removes
# the existing duplicates.
class Like < ApplicationRecord
  belongs_to :item
  belongs_to :user
  # A unique index is deliberately not added: existing duplicate rows would make the migration fail.
  validates :user_id, uniqueness: { scope: :item_id }, on: :create # rubocop:disable Rails/UniqueValidationWithoutIndex
end
