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

    it 'builds paths from the persisted name while an unsaved rename is pending', :aggregate_failures do
      user_event.name = 'unsaved'
      top_event.name = ''
      expect(event_page_path(user_event)).to eq "/boards/#{user_board.board_id}/events/user-ev"
      expect(edit_event_page_path(top_event)).to eq '/events/top-ev/edit'
    end

    it 'builds the board-scoped edit path for a user board event' do
      expect(edit_event_page_path(user_event)).to eq "/boards/#{user_board.board_id}/events/user-ev/edit"
    end
  end

  describe 'persisted_event_title' do
    let(:stored_event) { create(:event, title: 'Stored Title') }

    it 'returns the persisted title while an unsaved rename is pending' do
      stored_event.title = 'Unsaved Title'
      expect(persisted_event_title(stored_event)).to eq 'Stored Title'
    end

    it 'falls back to the in-memory title when the event has no stored title yet' do
      draft_event = build(:event, title: 'Draft Title')
      expect(persisted_event_title(draft_event)).to eq 'Draft Title'
    end
  end
end
