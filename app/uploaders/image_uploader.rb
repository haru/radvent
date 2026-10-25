# frozen_string_literal: true

# Validates both extension and content type to prevent content-type spoofing
class ImageUploader < CarrierWave::Uploader::Base
  storage :file

  # Resolves where this record's file lives: the protected area (outside public/, served only
  # through the authorized endpoint) unless the image is {#legacy?}. Files are never moved or
  # modified by this lookup.
  #
  # Note that {#url} is only meaningful for legacy images; link protected images through
  # +attachment_image_path+ instead.
  #
  # @return [String, Pathname] the root directory that +store_dir+ is relative to
  def root
    legacy? ? super : protected_root
  end

  # Whether this is an image uploaded before access control existed: a saved record whose file
  # is not in the protected area but is under public/, where it is served statically.
  # Cached (in-flight) files are never legacy, so they stay in the protected area even when they
  # replace a legacy image. Replacing a legacy image is not supported (there is no update action):
  # the old file would be resolved against the new name's root and left under public/.
  #
  # @return [Boolean]
  def legacy?
    stored_name = model && !model.new_record? && model.read_uploader(mounted_as)
    return false if cached? || stored_name.blank?

    !file_under?(protected_root, stored_name) && file_under?(CarrierWave.root, stored_name)
  end

  # Temporary files must never land under public/, where they would be served without authorization.
  #
  # @return [String] cache directory, relative to {#root}
  def cache_dir
    'uploads/tmp'
  end

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

  private

  def protected_root
    Rails.application.config.x.protected_upload_root
  end

  # @return [Boolean] whether +name+ is a file under +base+ at this record's store_dir
  def file_under?(base, name)
    Pathname.new(base).join(store_dir, name).file?
  end
end
