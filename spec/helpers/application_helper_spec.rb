# frozen_string_literal: true

require 'rails_helper'

describe ApplicationHelper do
  it "returns 'Advent Calendar' if RADVENT_TITLE is not setted." do
    ENV['RADVENT_TITLE'] = nil
    expect(system_title).to eq 'Advent Calendar'
  end

  it "returns 'ENV[RADVENT_TITLE]' value if RADVENT_TITLE is not setted." do
    ENV['RADVENT_TITLE'] = 'test'
    expect(system_title).to eq 'test'
  end

  describe 'event page paths' do
    let(:top_event) { create(:event, name: 'top-ev') }
    let(:user_board) { create(:board, :public_user) }
    let(:user_event) { create(:event, board: user_board, name: 'user-ev') }

    it 'builds the name-only path for a TOP board event' do
      expect(event_page_path(top_event)).to eq '/events/top-ev'
    end

    it 'builds the name-only edit path for a TOP board event' do
      expect(edit_event_page_path(top_event)).to eq '/events/top-ev/edit'
    end

    it 'builds the board-scoped path for a user board event' do
      expect(event_page_path(user_event)).to eq "/boards/#{user_board.board_id}/events/user-ev"
    end

    it 'builds the board-scoped edit path for a user board event' do
      expect(edit_event_page_path(user_event)).to eq "/boards/#{user_board.board_id}/events/user-ev/edit"
    end
  end
end
