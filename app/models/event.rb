class Event < ApplicationRecord
  has_many :advent_calendar_items, dependent: :destroy
  belongs_to :created_by, class_name: 'User'
  belongs_to :updated_by, class_name: 'User'
  validates :title, presence: true, uniqueness: true
  validates :name, presence: true, uniqueness: true, format: { with: /\A[-_a-z0-9]+\z/ }
  validate :start_and_end_dates_must_be_same_month

  private

  def start_and_end_dates_must_be_same_month
    return if start_date.blank? || end_date.blank?

    if start_date.month != end_date.month || start_date.year != end_date.year
      errors.add(:end_date, :different_month)
    end
  end

  public

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
