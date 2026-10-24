# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'boards/show' do
  let(:owner) { create(:user) }
  let(:board) { create(:board, :public_user, owner: owner) }

  before do
    assign(:board, board)
    assign(:events, [])
    allow(view).to receive_messages(current_user: nil, user_signed_in?: false)
  end

  it 'renders the board name' do
    render
    combined = rendered + view.content_for(:content).to_s + view.content_for(:jumbotron).to_s
    expect(combined).to include(board.name)
  end

  it 'links user board events to the board-scoped URL' do
    event = create(:event, board: board, name: 'user-ev', start_date: '2016-12-01', end_date: '2016-12-25')
    assign(:events, [event])
    render
    combined = rendered + view.content_for(:content).to_s
    expect(combined).to include("/boards/#{board.board_id}/events/user-ev")
  end

  it 'links TOP board events to the name-only URL' do
    event = create(:event, name: 'top-ev', start_date: '2016-12-01', end_date: '2016-12-25')
    assign(:board, event.board)
    assign(:events, [event])
    render
    expect(rendered + view.content_for(:content).to_s).to include('href="/events/top-ev"')
  end
end
