# frozen_string_literal: true

FactoryBot.define do
  factory :event do
    sequence :title do |n|
      "MyString#{n}"
    end
    sequence :name do |n|
      "name#{n}"
    end
    version { 1 }
    updated_at { '2017-11-07 17:49:53' }
    created_at { '2017-11-07 17:49:53' }
    start_date { '2017-11-07 17:49:53' }
    end_date { '2017-11-07 17:49:53' }
    association :created_by, factory: :user
    association :updated_by, factory: :user
  end
end
