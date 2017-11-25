FactoryGirl.define do
  factory :advent_calendar_item do
    user_name "nanonanomachine"
    comment "comment"
    user_id 1
    association :item
  end
end
