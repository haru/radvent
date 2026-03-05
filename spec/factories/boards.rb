# frozen_string_literal: true

FactoryBot.define do
  factory :board do
    sequence(:board_id) { |n| "board#{n}" }
    name { 'Test Board' }
    description { 'A test board' }
    board_type { :user }
    visibility { :public }
    association :owner, factory: :user

    trait :top do
      board_type { :top }
      board_id { nil }
      name { 'TOP' }
      visibility { nil }
      owner { nil }
    end

    trait :public_user do
      board_type { :user }
      visibility { :public }
    end

    trait :protected_user do
      board_type { :user }
      visibility { :protected }
    end

    trait :private_user do
      board_type { :user }
      visibility { :private }
    end
  end
end
