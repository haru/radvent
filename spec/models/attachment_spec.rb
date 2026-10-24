# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Attachment do
  let(:owner) { create(:user) }
  let(:member) { create(:user) }
  let(:outsider) { create(:user) }
  let(:admin) { create(:user, admin: true) }
  let(:board) { create(:board, :private_user, owner: owner) }
  let(:event) { create(:event, board: board) }
  let(:advent_calendar_item) { create(:advent_calendar_item, event: event, user: owner) }
  let(:attachment) { create(:attachment, advent_calendar_item: advent_calendar_item) }

  def orphan(attachment)
    attachment.update_column(:advent_calendar_item_id, 0) # rubocop:disable Rails/SkipsModelValidations
    attachment.reload
  end

  describe 'validations' do
    it 'requires an image' do
      expect(described_class.new(advent_calendar_item: advent_calendar_item)).not_to be_valid
    end
  end

  describe '#visible?' do
    before do
      create(:board_membership, board: board, user: member)
      create(:item, advent_calendar_item: advent_calendar_item)
    end

    it 'is true for a board member' do
      expect(attachment.visible?(member)).to be(true)
    end

    it 'is true for an admin' do
      expect(attachment.visible?(admin)).to be(true)
    end

    it 'is false for a non-member of a private board' do
      expect(attachment.visible?(outsider)).to be(false)
    end

    it 'is false for a nil user on a private board' do
      expect(attachment.visible?(nil)).to be(false)
    end

    it 'is true for a nil user on a public board' do
      board.update!(visibility: :public)
      expect(attachment.visible?(nil)).to be(true)
    end

    it 'is false (not an error) for an orphaned attachment' do
      expect(orphan(attachment).visible?(admin)).to be(false)
    end

    it 'reflects board changes without caching' do
      attachment.visible?(outsider)
      board.update!(visibility: :public)
      expect(attachment.visible?(outsider)).to be(true)
    end

    # @return [Array] [board_type, visibility, user_id] for each combination where the attachment and article differ
    def visibility_mismatches(boards, users)
      boards.product(users).filter_map do |b, user|
        advent_calendar_item.update!(event: create(:event, board: b))
        [b.board_type, b.visibility, user&.id] if attachment.visible?(user) != advent_calendar_item.visible?(user)
      end
    end

    it 'matches the article board visibility across board kinds and viewers' do
      boards = [create(:board, :top), create(:board, :public_user), create(:board, :protected_user), board]
      expect(visibility_mismatches(boards, [owner, member, outsider, admin, nil])).to be_empty
    end

    context 'when the article is not published yet' do
      before { event.update!(start_date: 1.year.from_now.beginning_of_month, end_date: 1.year.from_now.end_of_month) }

      it 'is false for a board member' do
        expect(attachment.visible?(member)).to be(false)
      end

      it 'is false for a guest on a public board' do
        board.update!(visibility: :public)
        expect(attachment.visible?(nil)).to be(false)
      end

      it 'is true for the article author' do
        expect(attachment.visible?(owner)).to be(true)
      end

      it 'is true for an admin' do
        expect(attachment.visible?(admin)).to be(true)
      end
    end
  end

  describe '#editable? and #deletable?' do
    it 'is false (not an error) for an orphaned attachment' do
      orphaned = orphan(attachment)
      expect([orphaned.editable?(admin), orphaned.deletable?(admin)]).to eq([false, false])
    end

    it 'follows the article' do
      expect([attachment.editable?(admin), attachment.deletable?(admin)]).to eq([true, true])
    end
  end
end
