# frozen_string_literal: true

# Handles image uploads for {AdventCalendarItem} entries and serves protected images only to
# viewers who may read the article.
class AttachmentsController < ApplicationController
  before_action :authenticate_user!, only: [:create]
  before_action :set_advent_calendar_item, only: [:create]
  before_action :authorize_editor!, only: [:create]

  # Serves a protected image, but only to viewers who may read the article it belongs to.
  # Denied, unknown, mismatched-filename, legacy (statically served), unreadable and missing
  # images all get the same 404.
  def show
    attachment = Attachment.includes(advent_calendar_item: [:item, { event: :board }]).find_by(id: params[:id])
    path = servable_path(attachment)
    return render_not_found unless path

    # "no-cache": browsers must re-request, so permission changes take effect immediately.
    # No validators are sent, so the image is downloaded again on each view.
    expires_now
    response.cache_control[:extras] = ['private'] # keep shared caches from storing it
    send_file path, disposition: 'inline', type: Marcel::MimeType.for(path)
  end

  # Saves the uploaded image and returns its URL as JSON.
  # Responds with 422 if validation or CarrierWave integrity checks fail.
  def create
    attachment = Attachment.new(attachment_params)

    if attachment.save
      render_upload_success(attachment)
    else
      render_upload_failure(attachment)
    end
  rescue CarrierWave::IntegrityError, CarrierWave::SizeMismatchError, CarrierWave::ProcessingError => e
    Rails.logger.warn("Image upload rejected: #{e.message}")
    render json: { success: false, error: e.message }, status: :unprocessable_content
  end

  private

  def set_advent_calendar_item
    @advent_calendar_item = AdventCalendarItem.find_by(id: params.dig(:attachment, :advent_calendar_item_id))
    return if @advent_calendar_item

    render json: { success: false, error: 'Advent calendar item not found' }, status: :not_found
  end

  def authorize_editor!
    return if current_user.admin? || @advent_calendar_item.editable_by?(current_user)

    Rails.logger.warn("Unauthorized upload attempt: user_id=#{current_user.id} item_id=#{@advent_calendar_item.id}")
    render json: { success: false, error: 'You are not authorized to upload images' }, status: :forbidden
  end

  # @return [Pathname, nil] the protected file to send, or nil when the viewer must get a 404
  def servable_path(attachment)
    return unless attachment && params[:filename] == attachment.image.identifier
    return unless attachment.visible?(current_user)
    return if attachment.image.legacy? # served statically at its original URL

    readable_file(attachment)
  end

  # Built by the uploader from the stored identifier only; params[:filename] never reaches the file system.
  def readable_file(attachment)
    path = Pathname.new(attachment.image.path)
    return path if path.file? && path.readable?

    Rails.logger.error("Attachment file missing or unreadable: attachment_id=#{attachment.id} path=#{path}")
    nil
  end

  # @return [String] the authorized endpoint path (not +image.url+, which only works for legacy images)
  def image_url_for(attachment)
    attachment_image_path(attachment, filename: attachment.image.identifier)
  end

  def attachment_params
    params.expect(attachment: %i[image advent_calendar_item_id])
  end

  def render_upload_success(attachment)
    Rails.logger.info("Image uploaded: attachment_id=#{attachment.id} user_id=#{current_user.id}")
    render json: { success: true, image_name: attachment.image.identifier, image_url: image_url_for(attachment) }
  end

  def render_upload_failure(attachment)
    Rails.logger.warn("Image upload failed: user_id=#{current_user.id} errors=#{attachment.errors.full_messages}")
    error_msg = attachment.errors.full_messages.first || t('controllers.attachments.create.fail_upload')
    render json: { success: false, error: error_msg }, status: :unprocessable_content
  end
end
