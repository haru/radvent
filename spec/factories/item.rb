# frozen_string_literal: true

FactoryBot.define do
  factory :item do
    title { 'title' }
    body { 'body' }
    advent_calendar_item
  end
end
