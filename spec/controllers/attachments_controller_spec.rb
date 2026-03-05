# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AttachmentsController, type: :controller do
  describe 'POST #create' do
    let(:user) { create(:user) }
    let(:event) { create(:event) }
    let(:advent_calendar_item) { create(:advent_calendar_item, event: event, user: user) }
    let(:item) { create(:item, advent_calendar_item: advent_calendar_item) }

    before do
      Attachment.destroy_all
      Item.destroy_all
      AdventCalendarItem.destroy_all
      Event.destroy_all
      User.destroy_all
      sign_in user
      item
    end

    it 'saves the new attachment in the database' do
      params = { attachment: build(:attachment, advent_calendar_item: advent_calendar_item).attributes }
      expect do
        post :create, params: params
      end.to change(Attachment, :count).by(1)
    end

    # TODO: Should be fixed.
    # it 'returns the json which has image_name and image_url' do
    #   image = Rack::Test::UploadedFile.new(
    #     File.join(Rails.root, 'spec', 'fixtures', 'files', 'test.jpg'), 'image/jpeg'
    #   )
    #   post :create, params: { attachment: create(:attachment, image: image).attributes }
    #   attachment = Attachment.first
    #   res = JSON.parse response.body
    #   expect(res['image_name']).to eq 'test.jpg'
    #   expect(res['image_url']).to eq "/uploads/attachment/image/#{attachment.id}/test.jpg"
    # end

    context 'when the attachment cannot be saved' do
      before do
        allow_any_instance_of(Attachment).to receive(:save).and_return(false)
        post :create, params: { attachment: attributes_for(:attachment) }
      end

      it 'returns error image_name in json' do
        expect(response.parsed_body['image_name']).to eq '画像のアップロードに失敗しました'
      end

      it 'returns nil image_url in json' do
        expect(response.parsed_body['image_url']).to be_nil
      end
    end
  end
end
