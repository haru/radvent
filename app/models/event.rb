class Event < ActiveRecord::Base
    has_many :advent_calendar_items, dependent: :destroy
    belongs_to :created_by, class_name: 'User'
    belongs_to :updated_by, class_name: 'User'
    validates :title, presence: true, uniqueness: true
    validates :name, presence: true, uniqueness: true, format: { with: /\A[-_a-z0-9]+\z/}
end
