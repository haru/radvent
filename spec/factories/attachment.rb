# frozen_string_literal: true

FactoryBot.define do
  factory :attachment do
    image { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/test.jpg").to_s, "image/jpeg") }
    association :advent_calendar_item
  end
end
