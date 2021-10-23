FactoryBot.define do
  factory :advent_calendar_item do
    user_name {'nanonanomachine'}
    comment {'comment'}
    created_at {Time.now}
    updated_at {Time.now}
    association :user
    association :event
    date {1}
  end
end
