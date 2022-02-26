FactoryBot.define do
  factory :attachment do
    image { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'fixtures', 'files', 'test.jpg'), "image/jpeg") }
    association :advent_calendar_item
  end
end
