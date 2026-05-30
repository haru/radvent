# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AttachmentsController do
  describe 'POST #create' do
    let(:owner) { create(:user) }
    let(:other_user) { create(:user) }
    let(:admin_user) { create(:user, admin: true) }
    let(:event) { create(:event) }
    let(:advent_calendar_item) { create(:advent_calendar_item, event: event, user: owner) }
    let(:item) { create(:item, advent_calendar_item: advent_calendar_item) }
    let(:image_file) do
      Rack::Test::UploadedFile.new(
        Rails.root.join('spec/fixtures/files/test.jpg').to_s,
        'image/jpeg'
      )
    end

    before do
      Attachment.destroy_all
      Item.destroy_all
      AdventCalendarItem.destroy_all
      Event.destroy_all
      User.destroy_all
      item
    end

    context 'when not logged in' do
      it 'redirects to sign in' do
        post :create, params: { attachment: { image: image_file, advent_calendar_item_id: advent_calendar_item.id } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when advent_calendar_item_id does not exist' do
      before { sign_in owner }

      it 'returns 404' do
        post :create, params: { attachment: { image: image_file, advent_calendar_item_id: 0 } }
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when logged in as a non-editor (not owner, not admin)' do
      before { sign_in other_user }

      it 'returns 403' do
        post :create, params: { attachment: { image: image_file, advent_calendar_item_id: advent_calendar_item.id } }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when logged in as the article owner' do
      before { sign_in owner }

      it 'saves the new attachment in the database' do
        expect do
          post :create, params: { attachment: { image: image_file, advent_calendar_item_id: advent_calendar_item.id } }
        end.to change(Attachment, :count).by(1)
      end

      it 'returns 200' do
        post :create, params: { attachment: { image: image_file, advent_calendar_item_id: advent_calendar_item.id } }
        expect(response).to have_http_status(:ok)
      end

      it 'returns image_url in json' do
        post :create, params: { attachment: { image: image_file, advent_calendar_item_id: advent_calendar_item.id } }
        expect(response.parsed_body['image_url']).to be_present
      end
    end

    context 'when logged in as admin' do
      before { sign_in admin_user }

      it 'saves the new attachment in the database' do
        expect do
          post :create, params: { attachment: { image: image_file, advent_calendar_item_id: advent_calendar_item.id } }
        end.to change(Attachment, :count).by(1)
      end
    end

    context 'when the attachment cannot be saved' do
      before do
        allow_any_instance_of(Attachment).to receive(:save).and_return(false)
        sign_in owner
        post :create, params: { attachment: { image: image_file, advent_calendar_item_id: advent_calendar_item.id } }
      end

      it 'returns success false in json' do
        expect(response.parsed_body['success']).to eq(false)
      end

      it 'returns error message in json' do
        expect(response.parsed_body['error']).to be_present
      end
    end
  end
end
