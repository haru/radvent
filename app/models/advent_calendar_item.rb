# Represents a calendar day slot in an advent calendar event.
#
# This model associates a user with a specific date (1-31) in an advent calendar event.
# It contains the actual article content through the has_one :item relationship.
class AdventCalendarItem < ApplicationRecord
  belongs_to :user
  belongs_to :event
  has_one :item, dependent: :destroy
  has_many :attachments, dependent: :destroy
  scope :prev, ->(item) { joins(:item, :event).where('event_id = ? and date < ?', item.event_id, item.date).order(:date).reverse_order }
  scope :next, ->(item) { joins(:item, :event).where('event_id = ? and date > ?', item.event_id, item.date).order(:date) }
  validates :user_id, :presence => true

  def published?
    self.item &&
      Date.new(year, month, self.date) <= Time.zone.today
  end

  def editable_by?(author)
    return false unless author
    if user
      return author.id == user.id
    else
      return author.name == user_name
    end
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
end
