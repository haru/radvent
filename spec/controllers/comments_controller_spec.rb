require 'rails_helper'

RSpec.describe CommentsController, :type => :controller do
  before do
    Comment.destroy_all
    Item.destroy_all
    AdventCalendarItem.destroy_all
    Event.destroy_all
    User.destroy_all
    @user = create(:user)
    sign_in @user
  end
  describe 'POST #create' do
    it 'saves the new comment in the database' do
      item = create(:item)
      expect {
        post :create, params: { comment: build(:comment, item: item).attributes }
      }.to change(Comment, :count).by(1)
    end

    it 'redirect to items#show if the new comment is saved' do
      item = create(:item)
      post :create, params: { comment: build(:comment, item: item).attributes }
      expect(response).to redirect_to item_path(id: item)
    end
  end

  describe 'DELETE #destroy' do
    before :each do
      @item = create(:item)
      @comment = create(:comment, item: @item)
    end

    it 'deletes the comment' do
      expect {
        delete :destroy, params: { id: @comment }
      }.to change(Comment, :count).by(-1)
    end

    it 'redirect to items#show if the comment is deleted' do
      delete :destroy, params: { id: @comment }
      expect(response).to redirect_to item_path(id: @item)
    end
  end
end
