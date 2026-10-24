# frozen_string_literal: true

# Represents an image attachment for an advent calendar item.
#
# This model stores image files uploaded via CarrierWave for advent calendar items.
class Attachment < ApplicationRecord
  include Permissionable

  belongs_to :advent_calendar_item
  mount_uploader :image, ImageUploader

  validates :image, presence: true

  # --- Permissionable implementation ---
  # An orphaned attachment is never visible, editable or deletable.

  # An attachment is visible exactly when its article is readable: the board is visible and the
  # article is published, or the viewer may edit it (author or admin) and so sees it before release.
  #
  # @param user [User, nil] the viewer (nil for a guest)
  # @return [Boolean]
  def visible?(user)
    return false unless advent_calendar_item&.visible?(user)

    advent_calendar_item.published? || user&.admin? || advent_calendar_item.editable_by?(user)
  end

  # @param user [User, nil]
  # @return [Boolean]
  def editable?(user)
    advent_calendar_item&.editable?(user) || false
  end

  # @param user [User, nil]
  # @return [Boolean]
  def deletable?(user)
    advent_calendar_item&.deletable?(user) || false
  end
end
