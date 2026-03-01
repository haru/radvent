# frozen_string_literal: true

# Manages image attachments for advent calendar items.
#
# Handles file uploads for the markdown editor.
class AttachmentsController < ApplicationController
  before_action :authenticate_user!, only: [:create]

  # Creates a new image attachment.
  #
  # @return [void]
  def create
    attachment = Attachment.new(attachment_params)

    if attachment.save
      render json: { image_name: attachment.image.identifier, image_url: image_url_for(attachment) }
    else
      render json: { image_name: t('controllers.attachments.create.fail_upload'), image_url: nil }
    end
  end

  private

  def image_url_for(attachment)
    return attachment.image.url if root_path == '/'

    "#{root_path}#{attachment.image.url}"
  end

  def attachment_params
    params.expect(attachment: %i[image advent_calendar_item_id])
  end
end
