# frozen_string_literal: true

FactoryBot.define do
  factory :attachment do
    image { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/test.jpg').to_s, 'image/jpeg') }
    advent_calendar_item

    # An image uploaded before access control existed: the file lives only under public/uploads.
    trait :legacy do
      after(:create) do |attachment|
        identifier = attachment.image.identifier
        protected_dir = Rails.application.config.x.protected_upload_root.join(attachment.image.store_dir)
        public_dir = Pathname.new(CarrierWave.root).join(attachment.image.store_dir)
        FileUtils.mkdir_p(public_dir)
        FileUtils.cp(protected_dir.join(identifier), public_dir.join(identifier))
        FileUtils.rm_rf(protected_dir)
      end
    end
  end
end
