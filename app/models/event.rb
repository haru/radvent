class Event < ActiveRecord::Base
  has_many :advent_calendar_items, dependent: :destroy
  belongs_to :created_by, class_name: 'User'
  belongs_to :updated_by, class_name: 'User'
  validates :title, presence: true, uniqueness: true
  validates :name, presence: true, uniqueness: true, format: { with: /\A[-_a-z0-9]+\z/ }

  def day_count
    (1 + (end_date - start_date)).to_i
  end

  def entry_count
    return 0 unless advent_calendar_items
    advent_calendar_items.length
  end

  def entry_percent
    return 0 unless day_count
    100 * entry_count / day_count
  end
end
