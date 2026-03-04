# frozen_string_literal: true

# Represents an image attachment for an advent calendar item.
#
# This model stores image files uploaded via CarrierWave for advent calendar items.
class Attachment < ApplicationRecord
  include Permissionable

  belongs_to :advent_calendar_item
  mount_uploader :image, ImageUploader

  # --- Permissionable implementation ---

  delegate :visible?, to: :advent_calendar_item

  delegate :editable?, to: :advent_calendar_item

  delegate :deletable?, to: :advent_calendar_item
end
