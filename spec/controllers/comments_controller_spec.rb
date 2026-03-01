# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CommentsController, type: :controller do
  let(:user) { create(:user) }

  before do
    Comment.destroy_all
    Item.destroy_all
    AdventCalendarItem.destroy_all
    Event.destroy_all
    User.destroy_all
    sign_in user
  end

  describe 'POST #create' do
    it 'saves the new comment in the database' do
      item = create(:item)
      expect do
        post :create, params: { comment: build(:comment, item: item).attributes }
      end.to change(Comment, :count).by(1)
    end

    it 'redirect to items#show if the new comment is saved' do
      item = create(:item)
      post :create, params: { comment: build(:comment, item: item).attributes }
      expect(response).to redirect_to item_path(id: item)
    end
  end

  describe 'DELETE #destroy' do
    let(:item) { create(:item) }
    let(:comment) { create(:comment, item: item) }

    before { comment }

    it 'deletes the comment' do
      expect do
        delete :destroy, params: { id: comment }
      end.to change(Comment, :count).by(-1)
    end

    it 'redirect to items#show if the comment is deleted' do
      delete :destroy, params: { id: comment }
      expect(response).to redirect_to item_path(id: item)
    end
  end
end
