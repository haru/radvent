# frozen_string_literal: true

# Represents a calendar day slot in an advent calendar event.
#
# This model associates a user with a specific date (1-31) in an advent calendar event.
# It contains the actual article content through the has_one :item relationship.
class AdventCalendarItem < ApplicationRecord
  include Permissionable

  belongs_to :user
  belongs_to :event
  has_one :item, dependent: :destroy
  has_many :attachments, dependent: :destroy
  validates :date, presence: true, numericality: { only_integer: true, in: 1..31 }
  validates :date, uniqueness: { scope: :event_id }, if: :will_save_change_to_date?
  scope :prev, lambda { |item|
    joins(:item, :event).where('event_id = ? and date < ?', item.event_id, item.date).order(:date).reverse_order
  }
  scope :next, lambda { |item|
    joins(:item, :event).where('event_id = ? and date > ?', item.event_id, item.date).order(:date)
  }

  def published?
    return false unless item

    Date.new(year, month, date) <= Time.zone.today
  rescue Date::Error, TypeError
    false
  end

  def editable_by?(author)
    return false unless author
    return author.id == user.id if user

    author.name == user_name
  end

  # Returns the year of the event's start date.
  #
  # @return [Integer] the year
  def year
    event.start_date.year
  end

  # Returns the month of the event's start date.
  #
  # @return [Integer] the month (1-12)
  def month
    event.start_date.month
  end

  # --- Permissionable implementation ---

  delegate :visible?, to: :event

  delegate :editable?, to: :event

  delegate :deletable?, to: :event
end
