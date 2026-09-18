# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BoardsHelper do
  let(:owner) { create(:user) }

  describe '#other_board_label' do
    it 'returns the system title for the TOP board' do
      expect(helper.other_board_label(build(:board, :top))).to eq(helper.system_title)
    end

    it 'returns the board name for a user board' do
      board = build(:board, :public_user, name: 'Ruby Board')
      expect(helper.other_board_label(board)).to eq('Ruby Board')
    end
  end

  describe '#other_board_path' do
    it 'returns the root path for the TOP board' do
      expect(helper.other_board_path(build(:board, :top))).to eq(root_path)
    end

    it 'returns the board path for a user board' do
      board = create(:board, :public_user, owner: owner, board_id: 'ruby')
      expect(helper.other_board_path(board)).to eq(board_path('ruby'))
    end
  end

  describe '#board_calendar_count' do
    it 'returns the number of events on the board' do
      board = create(:board, :public_user, owner: owner)
      create_list(:event, 2, board: board, created_by: owner, updated_by: owner)
      expect(helper.board_calendar_count(board)).to eq(2)
    end

    it 'returns zero for a board without events' do
      board = create(:board, :public_user, owner: owner)
      expect(helper.board_calendar_count(board)).to eq(0)
    end
  end

  describe '#board_published_item_count' do
    let(:board) { create(:board, :public_user, owner: owner) }
    let(:event) do
      create(:event, board: board, start_date: '2015-12-01', end_date: '2015-12-25',
                     created_by: owner, updated_by: owner)
    end

    before { allow(Time.zone).to receive(:today).and_return(Date.new(2015, 12, 2)) }

    it 'counts calendar items whose date has passed' do
      calendar_item = create(:advent_calendar_item, event: event, date: 1)
      create(:item, advent_calendar_item: calendar_item)
      expect(helper.board_published_item_count(board)).to eq(1)
    end

    it 'ignores calendar items whose date is still in the future' do
      calendar_item = create(:advent_calendar_item, event: event, date: 25)
      create(:item, advent_calendar_item: calendar_item)
      expect(helper.board_published_item_count(board)).to eq(0)
    end

    it 'ignores calendar items without an article' do
      create(:advent_calendar_item, event: event, date: 1)
      expect(helper.board_published_item_count(board)).to eq(0)
    end
  end
end
