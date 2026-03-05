# frozen_string_literal: true

require 'rails_helper'

describe Event do
  let(:user) { create(:user) }

  before do
    described_class.destroy_all
    AdventCalendarItem.destroy_all
    user
  end

  it 'returns 5 days from start_date to end_date' do
    event = build(:event, start_date: Date.parse('2019-12-01'), end_date: Date.parse('2019-12-05'))
    expect(event.day_count).to eq(5)
  end

  it 'returns 1 day for a single-day event' do
    event = build(:event, start_date: Date.parse('2019-12-01'), end_date: Date.parse('2019-12-01'))
    expect(event.day_count).to eq(1)
  end

  describe '#entry_count' do
    let(:event) { create(:event) }

    it 'returns 0 with no entries' do
      expect(event.entry_count).to eq(0)
    end

    it 'returns 1 after one entry is added' do
      create(:advent_calendar_item, event: event)
      event.reload
      expect(event.entry_count).to eq(1)
    end

    it 'returns 2 after two entries are added' do
      create(:advent_calendar_item, event: event)
      create(:advent_calendar_item, event: event)
      event.reload
      expect(event.entry_count).to eq(2)
    end
  end

  describe '#entry_percent' do
    let(:event) { create(:event, start_date: Date.parse('2019-12-01'), end_date: Date.parse('2019-12-05')) }

    it 'returns 0 with no entries' do
      expect(event.entry_percent).to eq(0)
    end

    it 'returns 20 with one entry out of five days' do
      create(:advent_calendar_item, event: event)
      event.reload
      expect(event.entry_percent).to eq(20)
    end

    it 'returns 100 when all days are filled' do
      5.times { create(:advent_calendar_item, event: event) }
      event.reload
      expect(event.entry_percent).to eq(100)
    end
  end

  describe '.creatable_on?' do
    let(:admin) { create(:user, admin: true) }
    let(:owner) { create(:user) }
    let(:member_user) { create(:user) }
    let(:stranger) { create(:user) }
    let(:top_board) { Board.find_or_create_by!(board_type: :top) { |b| b.name = 'TOP' } }
    let(:public_board) { create(:board, :public_user, owner: owner) }
    let(:protected_board) { create(:board, :protected_user, owner: owner) }
    let(:private_board) { create(:board, :private_user, owner: owner) }

    before do
      create(:board_membership, board: public_board, user: member_user)
      create(:board_membership, board: protected_board, user: member_user)
      create(:board_membership, board: private_board, user: member_user)
    end

    context 'when the board is a top board' do
      it 'allows admin' do
        expect(described_class.creatable_on?(top_board, admin)).to be true
      end

      it 'denies unauthenticated' do
        expect(described_class.creatable_on?(top_board, nil)).to be false
      end

      it 'denies owner (non-admin)' do
        expect(described_class.creatable_on?(top_board, owner)).to be false
      end

      it 'denies member' do
        expect(described_class.creatable_on?(top_board, member_user)).to be false
      end

      it 'denies stranger' do
        expect(described_class.creatable_on?(top_board, stranger)).to be false
      end
    end

    context 'when the board is a public UserBoard' do
      it 'allows admin' do
        expect(described_class.creatable_on?(public_board, admin)).to be true
      end

      it 'denies unauthenticated' do
        expect(described_class.creatable_on?(public_board, nil)).to be false
      end

      it 'allows any authenticated user (stranger)' do
        expect(described_class.creatable_on?(public_board, stranger)).to be true
      end

      it 'allows member' do
        expect(described_class.creatable_on?(public_board, member_user)).to be true
      end

      it 'allows owner' do
        expect(described_class.creatable_on?(public_board, owner)).to be true
      end
    end

    context 'when the board is a protected UserBoard' do
      it 'allows admin' do
        expect(described_class.creatable_on?(protected_board, admin)).to be true
      end

      it 'denies unauthenticated' do
        expect(described_class.creatable_on?(protected_board, nil)).to be false
      end

      it 'denies stranger (authenticated non-member)' do
        expect(described_class.creatable_on?(protected_board, stranger)).to be false
      end

      it 'allows member' do
        expect(described_class.creatable_on?(protected_board, member_user)).to be true
      end

      it 'allows owner' do
        expect(described_class.creatable_on?(protected_board, owner)).to be true
      end
    end

    context 'when the board is a private UserBoard' do
      it 'allows admin' do
        expect(described_class.creatable_on?(private_board, admin)).to be true
      end

      it 'denies unauthenticated' do
        expect(described_class.creatable_on?(private_board, nil)).to be false
      end

      it 'denies stranger' do
        expect(described_class.creatable_on?(private_board, stranger)).to be false
      end

      it 'allows member' do
        expect(described_class.creatable_on?(private_board, member_user)).to be true
      end

      it 'allows owner' do
        expect(described_class.creatable_on?(private_board, owner)).to be true
      end
    end
  end
end
