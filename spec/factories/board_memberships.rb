# frozen_string_literal: true

FactoryBot.define do
  factory :board_membership do
    association :board
    association :user
  end
end
