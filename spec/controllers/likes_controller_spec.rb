require 'rails_helper'

RSpec.describe LikesController, :type => :controller do
  before do
    Item.destroy_all
    AdventCalendarItem.destroy_all
    Event.destroy_all
    @user = create(:user, admin: false)
    sign_in @user
    @event = create(:event, name: 'hogehoge', title: 'foobar', start_date: '2016-12-01', end_date: '2016-12-30', created_by: @user, updated_by: @user)
    @advent_calendar_item = create(:advent_calendar_item, date: 1, event: @event, user: @user)
    @item = create(:item, advent_calendar_item: @advent_calendar_item)
  end
  describe 'POST create' do
    it 'returns http success' do
      post :create, params: { item_id: @item.id }, as: :turbo_stream
      expect(response).to have_http_status(:success)
    end
  end

  describe 'delete destroy' do
    it 'returns http success' do
      like = Like.create(user_id: @user.id, item: @item)
      delete :destroy, params: { item_id: @item.id, id: like.id }, as: :turbo_stream
      expect(response).to have_http_status(:success)
    end
  end
end
