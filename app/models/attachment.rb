# Represents an image attachment for an advent calendar item.
#
# This model stores image files uploaded via CarrierWave for advent calendar items.
class Attachment < ApplicationRecord
  belongs_to :advent_calendar_item
  mount_uploader :image, ImageUploader
end
