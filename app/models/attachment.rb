# frozen_string_literal: true

# Represents an image attachment for an advent calendar item.
#
# This model stores image files uploaded via CarrierWave for advent calendar items.
class Attachment < ApplicationRecord
  include Permissionable

  belongs_to :advent_calendar_item
  mount_uploader :image, ImageUploader

  # --- Permissionable implementation ---

  def visible?(user)
    advent_calendar_item.visible?(user)
  end

  def editable?(user)
    advent_calendar_item.editable?(user)
  end

  def deletable?(user)
    advent_calendar_item.deletable?(user)
  end
end
