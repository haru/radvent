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
    Rack::Test::UploadedFile.new(file.path, 'image/jpeg').tap { file.close(true) }
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

  describe 'storage location' do
    let(:protected_root) { Rails.application.config.x.protected_upload_root }

    it 'uses the protected root for an unsaved record' do
      expect(described_class.new(Attachment.new, :image).root.to_s).to eq(protected_root.to_s)
    end

    it 'uses the protected root for a saved record whose file is in the protected area' do
      expect(attachment.image.root.to_s).to eq(protected_root.to_s)
    end

    it 'caches uploads under a relative cache_dir' do
      expect(uploader.cache_dir).to eq('uploads/tmp')
    end

    it 'resolves a saved record with a protected file outside public/' do
      expect(uploader.root.to_s).not_to start_with(CarrierWave.root.to_s)
    end

    it 'stores the file under <protected root>/uploads/attachment/image/<id>/<identifier>' do
      path = protected_root.join("uploads/attachment/image/#{attachment.id}/#{attachment.image.identifier}")
      expect(path).to exist
    end

    it 'does not write the file under public/uploads' do
      expect(legacy_upload_dir(attachment)).not_to exist
    end

    it 'is not legacy' do
      expect(attachment.image).not_to be_legacy
    end

    it 'keeps the store_dir layout' do
      expect(uploader.store_dir).to eq("uploads/attachment/image/#{attachment.id}")
    end
  end

  describe 'legacy images' do
    let(:legacy) { create(:attachment, :legacy) }

    after { FileUtils.rm_rf(legacy_upload_dir(legacy)) }

    it 'uses the public root when the file exists only under public/uploads' do
      expect(legacy.reload.image.root.to_s).to eq(Pathname.new(CarrierWave.root).to_s)
    end

    it 'is legacy' do
      expect(legacy.reload.image).to be_legacy
    end

    it 'keeps the legacy static URL' do
      expect(legacy.reload.image.url).to eq("/uploads/attachment/image/#{legacy.id}/#{legacy.image.identifier}")
    end

    it 'falls back to the protected root, without raising, when the file exists in neither area' do
      # Search order is protected first; "missing everywhere" is resolved by the controller as 404.
      FileUtils.rm_rf(legacy_upload_dir(legacy))
      expect(legacy.reload.image.root.to_s).to eq(Rails.application.config.x.protected_upload_root.to_s)
    end

    it 'is not legacy when the file exists in neither area' do
      FileUtils.rm_rf(legacy_upload_dir(legacy))
      expect(legacy.reload.image).not_to be_legacy
    end

    it 'caches a replacement upload in the protected area, never under public/' do
      image = legacy.reload.image
      image.cache!(upload_file('test.jpg', 'image/jpeg'))
      expect(image.file.path).to start_with(Rails.application.config.x.protected_upload_root.to_s)
    end
  end
end
