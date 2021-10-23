FactoryBot.define do
  factory :item do
    title {'title'}
    body {'body'}
    association :advent_calendar_item
  end
end
