class Item < ActiveRecord::Base
  belongs_to :advent_calendar_item
  has_many :comments, -> { order('id') }, dependent: :destroy
  has_many :likes, dependent: :destroy

  def title
    self[:title].presence || I18n.t('activerecord.attributes.item.title_empty')
  end

  def editable_by?(author)
    advent_calendar_item.editable_by? author
  end

  def liked_by?(user)
    return false unless user
    likes.find_by(user_id: user.id) != nil
  end
end
