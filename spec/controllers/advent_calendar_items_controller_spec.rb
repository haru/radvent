# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdventCalendarItemsController, type: :controller do
  let(:user) { create(:user, admin: false) }

  before do
    Item.destroy_all
    AdventCalendarItem.destroy_all
    Event.destroy_all
    User.destroy_all
    sign_in user
  end

  describe 'GET #show' do
    it 'assigns the requested advent_calendar_item to @advent_calendar_item' do
      advent_calendar_item = create(:advent_calendar_item, user: user)
      get :show, params: { id: advent_calendar_item }
      expect(assigns(:advent_calendar_item)).to eq advent_calendar_item
    end

    it 'renders the :show template' do
      advent_calendar_item = create(:advent_calendar_item)
      get :show, params: { id: advent_calendar_item }
      expect(response).to render_template :show
    end
  end

  describe 'GET #new' do
    it 'assigns a new advent_calendar_item to @advent_calendar_item' do
      get :new, params: { date: 1 }
      expect(assigns(:advent_calendar_item)).to be_a_new(AdventCalendarItem)
    end

    it 'assigns the requested date to @advent_calendar_item.date' do
      get :new, params: { date: 1 }
      expect(assigns(:advent_calendar_item).date).to eq 1
    end

    it 'renders the :new template' do
      get :new, params: { date: 1 }
      expect(response).to render_template :new
    end
  end

  describe 'GET #edit' do
    it 'assigns the requested advent_calendar_item to @advent_calendar_item' do
      advent_calendar_item = create(:advent_calendar_item)
      get :edit, params: { id: advent_calendar_item }
      expect(assigns(:advent_calendar_item)).to eq advent_calendar_item
    end

    it 'renders the :edit template' do
      advent_calendar_item = create(:advent_calendar_item, user: user)
      get :edit, params: { id: advent_calendar_item }
      expect(response).to render_template :edit
    end
  end

  describe 'POST #create' do
    it 'saves the new advent_calendar_item in the database' do
      event = create(:event)
      params = { advent_calendar_item: build(:advent_calendar_item, event: event).attributes }
      expect { post :create, params: params }.to change(AdventCalendarItem, :count).by(1)
    end

    it 'redirects to advent_calendar_items#show' do
      event = create(:event)
      params = { advent_calendar_item: build(:advent_calendar_item, event: event).attributes }
      post :create, params: params
      expect(response).to redirect_to advent_calendar_item_path(id: AdventCalendarItem.first.id)
    end
  end

  describe 'PATCH #update' do
    let(:advent_calendar_item) { create(:advent_calendar_item, user: user) }

    it 'locates the requested @advent_calendar_item' do
      patch :update, params: { id: advent_calendar_item,
                               advent_calendar_item: attributes_for(:advent_calendar_item) }
      expect(assigns(:advent_calendar_item)).to eq(advent_calendar_item)
    end

    context 'when changing attributes' do
      before do
        patch :update, params: {
          id: advent_calendar_item,
          advent_calendar_item: attributes_for(:advent_calendar_item,
                                               user_name: 'user_name_updated', comment: 'comment_updated')
        }
        advent_calendar_item.reload
      end

      it 'updates user_name' do
        expect(advent_calendar_item.user_name).to eq('user_name_updated')
      end

      it 'updates comment' do
        expect(advent_calendar_item.comment).to eq('comment_updated')
      end
    end

    it 'renders the :edit if the advent_calendar_item is not updated' do
      allow_any_instance_of(AdventCalendarItem).to receive(:save).and_return(false)
      patch :update, params: { id: advent_calendar_item,
                               advent_calendar_item: attributes_for(:advent_calendar_item) }
      expect(response).to render_template :edit
    end

    it 'redirects to advent_calendar_item#show if the advent_calendar_item is updated' do
      patch :update, params: { id: advent_calendar_item,
                               advent_calendar_item: attributes_for(:advent_calendar_item) }
      expect(response).to redirect_to advent_calendar_item_path(advent_calendar_item)
    end
  end
end
