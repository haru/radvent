# frozen_string_literal: true

FactoryBot.define do
  factory :advent_calendar_item do
    user_name { 'nanonanomachine' }
    comment { 'comment' }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }
    association :user
    association :event
    date { 1 }
  end
end
