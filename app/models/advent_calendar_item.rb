class AdventCalendarItem < ActiveRecord::Base
  belongs_to :user
  belongs_to :event
  has_one :item, dependent: :destroy
  has_many :attachments, dependent: :destroy
  scope :prev, ->(item) { joins(:item, :event).where("event_id = ? and date < ?", item.event_id, item.date).order(:date).reverse_order}
  scope :next, ->(item) { joins(:item, :event).where("event_id = ? and date > ?", item.event_id, item.date).order(:date)}
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

  def year
    event.start_date.year
  end

  def month
    event.start_date.month
  end
end
