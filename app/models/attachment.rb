class Attachment < ApplicationRecord
  belongs_to :advent_calendar_item
  mount_uploader :image, ImageUploader
end
