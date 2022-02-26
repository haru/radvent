# coding: utf-8
require 'rails_helper'

RSpec.describe AttachmentsController, :type => :controller do
  describe 'POST #create' do
    before do
      Attachment.destroy_all
      Item.destroy_all
      AdventCalendarItem.destroy_all
      Event.destroy_all
      User.destroy_all
      @user = create(:user)
      sign_in @user
      @event = create(:event)
      @advent_calendar_item = create(:advent_calendar_item, event: @event, user: @user)
      @item = create(:item, advent_calendar_item: @advent_calendar_item)
    end
    it 'saves the new attachment in the database' do
      expect {
        post :create, params: { attachment: build(:attachment, advent_calendar_item: @advent_calendar_item).attributes }
      }.to change(Attachment, :count).by(1)
    end

    # TODO: Should be fixed.
    # it 'returns the json which has image_name and image_url' do
    #   image = Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'fixtures', 'files', 'test.jpg'), "image/jpeg") 
    #   attr = create(:attachment, advent_calendar_item: @advent_calendar_item, image: image.attributes).attributes
    #   post :create, params: { attachment: create(:attachment, advent_calendar_item: @advent_calendar_item, image: image).attributes }
    #   attachment = Attachment.first
    #   res = JSON.parse response.body
    #   expect(res['image_name']).to eq 'test.jpg'
    #   expect(res['image_url']).to eq "/uploads/attachment/image/#{attachment.id}/test.jpg"
    # end

    it 'retuns the json for fail if the new attachment is not saved' do
      allow_any_instance_of(Attachment).to receive(:save).and_return(false)
      post :create, params: { attachment: attributes_for(:attachment) }
      res = JSON.parse response.body
      expect(res['image_name']).to eq '画像のアップロードに失敗しました'
      expect(res['image_url']).to be_nil
    end
  end
end
