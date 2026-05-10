# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    user_name { 'nanonanomachine' }
    body { 'body' }
    item
  end
end
