# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImageUploader do
  let(:attachment) { create(:attachment) }
  let(:uploader) { described_class.new(attachment, :image) }

  def upload_file(filename, content_type)
    Rack::Test::UploadedFile.new(
      Rails.root.join("spec/fixtures/files/#{filename}").to_s,
      content_type
    )
  end

  def oversized_jpg
    file = Tempfile.new(['large', '.jpg'])
    file.write('x' * (10.megabytes + 1))
    file.rewind
    Rack::Test::UploadedFile.new(file.path, 'image/jpeg')
  end

  describe 'extension_allowlist' do
    it 'accepts .jpg files' do
      uploader.store!(upload_file('test.jpg', 'image/jpeg'))
      expect(uploader.file).to be_present
    end

    it 'accepts .gif files' do
      uploader.store!(upload_file('test.gif', 'image/gif'))
      expect(uploader.file).to be_present
    end

    it 'accepts .webp files' do
      uploader.store!(upload_file('test.webp', 'image/webp'))
      expect(uploader.file).to be_present
    end

    it 'rejects .pdf files' do
      expect { uploader.store!(upload_file('test.pdf', 'application/pdf')) }
        .to raise_error(CarrierWave::IntegrityError)
    end
  end

  describe 'content_type_allowlist' do
    it 'accepts image/jpeg' do
      uploader.store!(upload_file('test.jpg', 'image/jpeg'))
      expect(uploader.file).to be_present
    end

    it 'accepts image/gif' do
      uploader.store!(upload_file('test.gif', 'image/gif'))
      expect(uploader.file).to be_present
    end

    it 'accepts image/webp' do
      uploader.store!(upload_file('test.webp', 'image/webp'))
      expect(uploader.file).to be_present
    end
  end

  describe 'size_range' do
    it 'accepts files within 10MB' do
      uploader.store!(upload_file('test.jpg', 'image/jpeg'))
      expect(uploader.file).to be_present
    end

    it 'rejects files larger than 10MB' do
      expect { uploader.store!(oversized_jpg) }.to raise_error(CarrierWave::IntegrityError)
    end
  end
end
