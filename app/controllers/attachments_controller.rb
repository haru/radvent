# frozen_string_literal: true

# Handles image file uploads attached to {AdventCalendarItem} entries.
class AttachmentsController < ApplicationController
  before_action :authenticate_user!, only: [:create]
  before_action :set_advent_calendar_item, only: [:create]
  before_action :authorize_editor!, only: [:create]

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
    render_not_found and return unless @advent_calendar_item
  end

  def authorize_editor!
    return if current_user.admin? || @advent_calendar_item.editable_by?(current_user)

    Rails.logger.warn("Unauthorized upload attempt: user_id=#{current_user.id} item_id=#{@advent_calendar_item.id}")
    render_forbidden
  end

  # CarrierWave url starts with /, so only prepend root_path for subpath mounts
  def image_url_for(attachment)
    return attachment.image.url if root_path == '/'

    "#{root_path.chomp('/')}#{attachment.image.url}"
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
