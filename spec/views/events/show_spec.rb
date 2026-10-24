# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'events/show', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:event_owner) { create(:user) }
  let(:admin_user) { create(:user, admin: true) }
  let(:other_user) { create(:user) }
  let(:owned_event) do
    create(:event, name: 'owned-event', title: 'Owned Event', start_date: '2016-12-01', end_date: '2016-12-25',
                   created_by: event_owner)
  end

  context 'when user is event owner' do
    before do
      sign_in event_owner
    end

    it 'renders pencil icon' do
      get show_event_path(owned_event.name)
      expect(response.body).to include('fa-pencil-alt')
    end

    it 'links pencil icon to edit path' do
      get show_event_path(owned_event.name)
      expect(response.body).to include(edit_event_path(owned_event.name))
    end
  end

  context 'when user is admin' do
    before do
      sign_in admin_user
    end

    it 'renders pencil icon' do
      get show_event_path(owned_event.name)
      expect(response.body).to include('fa-pencil-alt')
    end

    it 'links pencil icon to edit path' do
      get show_event_path(owned_event.name)
      expect(response.body).to include(edit_event_path(owned_event.name))
    end
  end

  context 'when user is not event owner and not admin' do
    before do
      sign_in other_user
    end

    it 'does not render pencil icon' do
      get show_event_path(owned_event.name)
      expect(response.body).not_to include('fa-pencil-alt')
    end

    it 'does not link to edit path' do
      get show_event_path(owned_event.name)
      expect(response.body).not_to include(edit_event_path(owned_event.name))
    end
  end

  context 'when user is not authenticated' do
    it 'does not render pencil icon' do
      get show_event_path(owned_event.name)
      expect(response.body).not_to include('fa-pencil-alt')
    end

    it 'does not link to edit path' do
      get show_event_path(owned_event.name)
      expect(response.body).not_to include(edit_event_path(owned_event.name))
    end
  end

  context 'when an article has duplicate like rows' do
    let(:liked_item) do
      create(:item, advent_calendar_item: create(:advent_calendar_item, event: owned_event, user: event_owner, date: 3))
    end

    it 'shows the like count with each user counted once' do
      2.times { Like.new(user: other_user, item: liked_item).save!(validate: false) }
      sign_in other_user
      get show_event_path(owned_event.name)
      expect(response.body).to match(%r{far fa-heart"></i>\s*1\s*<})
    end
  end

  context 'when the event is on a user board' do
    let(:board) { create(:board, :public_user) }
    let(:board_event) do
      create(:event, board: board, name: 'user-ev', title: 'User Ev', start_date: '2016-12-01',
                     end_date: '2016-12-25', created_by: event_owner)
    end

    before { sign_in event_owner }

    it 'links the pencil icon to the board-scoped edit path' do
      get board_event_path(board.board_id, board_event.name)
      expect(response.body).to include("/boards/#{board.board_id}/events/user-ev/edit")
    end
  end
end
