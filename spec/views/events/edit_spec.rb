# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'events/edit', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:creator) { create(:user) }

  before { sign_in creator }

  it 'targets the name-only URL for a TOP board event', :aggregate_failures do
    event = create(:event, name: 'top-ev', start_date: '2016-12-01', end_date: '2016-12-25', created_by: creator)
    get edit_event_path(event.name)
    expect(response.body).to include('action="/events/top-ev"')
    expect(response.body).not_to include('/boards/')
  end

  it 'targets the board-scoped URL for a user board event' do
    board = create(:board, :public_user)
    event = create(:event, board: board, name: 'user-ev', start_date: '2016-12-01', end_date: '2016-12-25',
                           created_by: creator)
    get edit_board_event_path(board.board_id, event.name)
    expect(response.body).to include(%(action="/boards/#{board.board_id}/events/user-ev"))
  end
end
