# frozen_string_literal: true

# Validates both extension and content type to prevent content-type spoofing
class ImageUploader < CarrierWave::Uploader::Base
  storage :file

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def extension_allowlist
    %w[jpg jpeg png gif webp]
  end

  def content_type_allowlist
    %r{\Aimage/(jpeg|png|gif|webp)\z}
  end

  def size_range
    1..(10.megabytes)
  end
end
