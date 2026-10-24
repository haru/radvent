# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LikesController do
  render_views

  include_context 'with a board item world'

  let(:user) { world[:outsider] }
  let(:target) { world[:item] }
  let(:author) { world[:author] }

  before { sign_in user }

  # Counts the likes of the target item.
  #
  # @return [Integer] the number of rows
  def likes_count
    Like.where(item_id: target.id).count
  end

  describe 'POST create' do
    %i[turbo_stream html].each do |format|
      it "redirects an anonymous #{format} request to sign-in without liking", :aggregate_failures do
        sign_out user
        post :create, params: { item_id: target.id }, as: format
        expect(response).to have_http_status(:redirect).or have_http_status(:unauthorized)
        expect(likes_count).to eq 0
      end
    end

    it 'responds 404 for a missing item', :aggregate_failures do
      post :create, params: { item_id: Item.maximum(:id) + 1 }, as: :turbo_stream
      expect(response).to have_http_status(:not_found)
      expect(Like.count).to eq 0
    end

    context 'when the board is private' do
      let(:visibility) { :private }

      it 'responds 404 to a non-member without liking', :aggregate_failures do
        post :create, params: { item_id: target.id }, as: :turbo_stream
        expect(response).to have_http_status(:not_found)
        expect(likes_count).to eq 0
      end
    end

    context 'when the item is not yet published' do
      let(:item_date) { 20 }

      %i[outsider author owner admin].each do |role|
        it "responds 404 to #{role} without liking", :aggregate_failures do
          sign_in world[role]
          post :create, params: { item_id: target.id }, as: :turbo_stream
          expect(response).to have_http_status(:not_found)
          expect(likes_count).to eq 0
        end
      end
    end

    it 'creates one like for a readable item', :aggregate_failures do
      expect { post :create, params: { item_id: target.id }, as: :turbo_stream }.to change(Like, :count).by(1)
      expect(response).to have_http_status(:success)
    end

    it 'redirects to the item for an HTML request' do
      post :create, params: { item_id: target.id }
      expect(response).to redirect_to(target)
    end

    it 'does not add a second like and shows the liked state', :aggregate_failures do
      post :create, params: { item_id: target.id }, as: :turbo_stream
      expect { post :create, params: { item_id: target.id }, as: :turbo_stream }.not_to change(Like, :count)
      expect(response).to have_http_status(:success)
      expect(response.body).to include('fas fa-heart')
    end
  end

  describe 'DELETE destroy' do
    it 'redirects an anonymous request to sign-in', :aggregate_failures do
      sign_out user
      delete :destroy, params: { item_id: target.id, id: 1 }, as: :turbo_stream
      expect(response).to have_http_status(:redirect).or have_http_status(:unauthorized)
    end

    it 'responds 404 for a missing item' do
      delete :destroy, params: { item_id: Item.maximum(:id) + 1, id: 1 }, as: :turbo_stream
      expect(response).to have_http_status(:not_found)
    end

    context 'when the board became private after the like' do
      let(:visibility) { :private }

      it 'responds 404 and keeps the like', :aggregate_failures do
        Like.create!(user: user, item: target)
        delete :destroy, params: { item_id: target.id, id: 1 }, as: :turbo_stream
        expect(response).to have_http_status(:not_found)
        expect(likes_count).to eq 1
      end
    end

    it 'succeeds without error when the user has not liked', :aggregate_failures do
      expect { delete :destroy, params: { item_id: target.id, id: 1 }, as: :turbo_stream }
        .not_to change(Like, :count)
      expect(response).to have_http_status(:success)
    end

    it 'removes only the user like and keeps those of others', :aggregate_failures do
      Like.create!(user: user, item: target)
      Like.create!(user: author, item: target)
      expect { delete :destroy, params: { item_id: target.id, id: 1 }, as: :turbo_stream }
        .to change(Like, :count).by(-1)
      expect(Like.where(item_id: target.id).pluck(:user_id)).to eq [author.id]
    end

    it 'removes every duplicate row of the user', :aggregate_failures do
      2.times { Like.new(user: user, item: target).save!(validate: false) }
      Like.create!(user: author, item: target)
      delete :destroy, params: { item_id: target.id, id: 1 }, as: :turbo_stream
      expect(Like.where(item_id: target.id).pluck(:user_id)).to eq [author.id]
    end

    it 'does not delete the like of another user addressed by id', :aggregate_failures do
      others = Like.create!(user: author, item: target)
      delete :destroy, params: { item_id: target.id, id: others.id }, as: :turbo_stream
      expect(response).to have_http_status(:success)
      expect(Like.exists?(others.id)).to be true
    end
  end

  describe 'rendered like area' do
    context 'when the author has duplicate like rows and an HTML-like name' do
      before do
        author.update!(name: '<b>x</b>')
        2.times { Like.new(user: author, item: target).save!(validate: false) }
        post :create, params: { item_id: target.id }, as: :turbo_stream
      end

      it 'lists the escaped name once', :aggregate_failures do
        expect(response.body.scan('&amp;lt;b&amp;gt;x&amp;lt;/b&amp;gt;').size).to eq 1
        expect(response.body).not_to include('<b>x</b>')
      end

      it 'counts the author once besides the new like' do
        expect(response.body).to match(%r{fa-heart"></i>\s*2\s*</button>}m)
      end
    end

    it 'builds the cancel URL from the viewer like on this item', :aggregate_failures do
      other_like = Like.create!(user: user, item: create(:item))
      this_like = Like.create!(user: user, item: target)
      post :create, params: { item_id: target.id }, as: :turbo_stream
      expect(response.body).to include("/items/#{target.id}/likes/#{this_like.id}")
      expect(response.body).not_to include("/likes/#{other_like.id}")
    end
  end
end
