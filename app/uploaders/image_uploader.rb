# frozen_string_literal: true

# Validates both extension and content type to prevent content-type spoofing
class ImageUploader < CarrierWave::Uploader::Base
  storage :file

  # @return [String] upload directory scoped by model class, mount point, and record ID
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # @return [Array<String>] permitted file extensions
  def extension_allowlist
    %w[jpg jpeg png gif webp]
  end

  # @return [Regexp] permitted MIME types; rejects content-type spoofing attempts
  def content_type_allowlist
    %r{\Aimage/(jpeg|png|gif|webp)\z}
  end

  # @return [Range] accepted file size range (1 byte … 10 MB)
  def size_range
    1..(10.megabytes)
  end
end
