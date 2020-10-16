require 'rails_helper'

RSpec.describe CommentsController, :type => :controller do
  before do
    @user = create(:user)
    sign_in @user
  end
  describe 'POST #create' do
    it 'saves the new comment in the database' do
      expect {
        post :create, params: { comment: attributes_for(:comment, item_id: 1) }
      }.to change(Comment, :count).by(1)
    end

    it 'redirect to items#show if the new comment is saved' do
      post :create, params: { comment: attributes_for(:comment, item_id: 1) }
      expect(response).to redirect_to item_path(id: 1)
    end
  end

  describe 'DELETE #destroy' do
    before :each do
      @comment = create(:comment, item_id: 1)
    end

    it 'deletes the comment' do
      expect {
        delete :destroy, params: { id: @comment }
      }.to change(Comment, :count).by(-1)
    end

    it 'redirect to items#show if the comment is deleted' do
      delete :destroy, params: { id: @comment }
      expect(response).to redirect_to item_path(id: 1)
    end
  end
end
