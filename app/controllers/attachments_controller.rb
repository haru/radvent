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
      if root_path == '/'
        url = attachment.image.url
      else
        url = "#{root_path}#{attachment.image.url}"
      end
      render json: {
        image_name: attachment.image.identifier,
        image_url: url,
      }
    else
      render json: {
        image_name: t('controllers.attachments.create.fail_upload'),
        image_url: nil,
      }
    end
  end

  private

  def attachment_params
    params.require(:attachment).permit(:image, :advent_calendar_item_id)
  end
end
