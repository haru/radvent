# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Board, type: :model do
  let(:owner) { create(:user) }

  # --- Validations ---
  describe 'validations' do
    describe 'board_type' do
      it 'is invalid without board_type' do
        board = build(:board, board_type: nil)
        expect(board).not_to be_valid
      end
    end

    describe 'name' do
      it 'is invalid without name' do
        board = build(:board, name: nil)
        expect(board).not_to be_valid
      end
    end

    describe 'board_id format' do
      it 'is valid with lowercase alphanumeric and hyphens' do
        board = build(:board, board_id: 'my-board-2024')
        expect(board).to be_valid
      end

      it 'normalizes uppercase to lowercase and becomes valid' do
        board = build(:board, board_id: 'MyBoard')
        expect(board).to be_valid
      end

      it 'normalizes the board_id to lowercase' do
        board = build(:board, board_id: 'MyBoard')
        board.valid?
        expect(board.board_id).to eq('myboard')
      end

      it 'is invalid with spaces' do
        board = build(:board, board_id: 'my board')
        expect(board).not_to be_valid
      end

      it 'is invalid when blank' do
        board = build(:board, board_id: '')
        expect(board).not_to be_valid
      end

      it 'is invalid when longer than 64 characters' do
        board = build(:board, board_id: 'a' * 65)
        expect(board).not_to be_valid
      end

      it 'is valid when exactly 64 characters' do
        board = build(:board, board_id: 'a' * 64)
        expect(board).to be_valid
      end

      it 'is invalid with reserved words' do
        Board::RESERVED_IDS.each do |reserved|
          board = build(:board, board_id: reserved)
          expect(board).not_to be_valid, "expected #{reserved} to be invalid"
        end
      end

      it 'strips whitespace before validation' do
        board = build(:board, board_id: '  myboard  ')
        board.valid?
        expect(board.board_id).to eq('myboard')
      end

      it 'is invalid when containing only numbers' do
        expect(build(:board, board_id: '123')).not_to be_valid
      end

      it 'is invalid when containing only symbols' do
        expect(build(:board, board_id: '-_-')).not_to be_valid
      end

      it 'is invalid when starting with a hyphen' do
        expect(build(:board, board_id: '-myboard')).not_to be_valid
      end

      it 'is invalid when ending with a hyphen' do
        expect(build(:board, board_id: 'myboard-')).not_to be_valid
      end

      it 'is invalid when starting with an underscore' do
        expect(build(:board, board_id: '_myboard')).not_to be_valid
      end

      it 'is invalid when ending with an underscore' do
        expect(build(:board, board_id: 'myboard_')).not_to be_valid
      end

      it 'is valid with an underscore in the middle' do
        board = build(:board, board_id: 'my_board')
        expect(board).to be_valid
      end
    end

    describe 'board_id uniqueness' do
      it 'is invalid with a duplicate board_id' do
        create(:board, board_id: 'unique-board')
        board = build(:board, board_id: 'unique-board')
        expect(board).not_to be_valid
      end
    end

    describe 'visibility' do
      it 'is invalid without visibility' do
        board = build(:board, visibility: nil)
        expect(board).not_to be_valid
      end
    end

    describe 'owner_id' do
      it 'is invalid without owner' do
        board = build(:board, owner: nil)
        expect(board).not_to be_valid
      end
    end

    context 'when board_type is top' do
      it 'is valid with no board_id, no visibility, no owner' do
        board = build(:board, :top)
        expect(board).to be_valid
      end

      it 'is invalid if a second top board is created' do
        create(:board, :top)
        board = build(:board, :top)
        expect(board).not_to be_valid
      end
    end
  end

  # --- Enums ---
  describe 'enums' do
    it 'uses board_type_top? predicate' do
      board = build(:board, :top)
      expect(board.board_type_top?).to be true
    end

    it 'uses board_type_user? predicate' do
      board = build(:board, :public_user)
      expect(board.board_type_user?).to be true
    end

    it 'uses visibility_public? predicate' do
      board = build(:board, :public_user)
      expect(board.visibility_public?).to be true
    end

    it 'uses visibility_protected? predicate' do
      board = build(:board, :protected_user)
      expect(board.visibility_protected?).to be true
    end

    it 'uses visibility_private? predicate' do
      board = build(:board, :private_user)
      expect(board.visibility_private?).to be true
    end
  end

  # --- Associations ---
  describe 'associations' do
    it 'belongs_to owner' do
      board = create(:board, :public_user)
      expect(board.owner).to be_a(User)
    end

    it 'has many board_memberships' do
      board = create(:board, :public_user)
      user = create(:user)
      create(:board_membership, board: board, user: user)
      expect(board.board_memberships.count).to eq(1)
    end

    it 'has many members through board_memberships' do
      board = create(:board, :public_user)
      user = create(:user)
      create(:board_membership, board: board, user: user)
      expect(board.members).to include(user)
    end

    it 'has many events' do
      board = create(:board, :top)
      expect(board.events).to be_empty
    end
  end

  # --- Permission helpers ---
  describe '#member?' do
    let(:board) { create(:board, :private_user) }
    let(:member_user) { create(:user) }

    before { create(:board_membership, board: board, user: member_user) }

    it 'returns true for a board member' do
      expect(board.member?(member_user)).to be true
    end

    it 'returns false for a non-member' do
      expect(board.member?(create(:user))).to be false
    end

    it 'returns false for nil' do
      expect(board.member?(nil)).to be false
    end
  end

  describe '#owner?' do
    let(:board) { create(:board, :public_user) }

    it 'returns true for the owner' do
      expect(board.owner?(board.owner)).to be true
    end

    it 'returns false for another user' do
      expect(board.owner?(create(:user))).to be false
    end

    it 'returns false for nil' do
      expect(board.owner?(nil)).to be false
    end
  end

  # --- Permissionable truth table for Board ---
  describe 'Permissionable (Board itself)' do
    context 'with a TopBoard' do
      let(:board) { create(:board, :top) }
      let(:admin) { create(:user, admin: true) }
      let(:stranger) { create(:user) }

      it 'is visible to nil' do
        expect(board.visible?(nil)).to be true
      end

      it 'is not editable by stranger' do
        expect(board.editable?(stranger)).to be false
      end

      it 'is editable by admin' do
        expect(board.editable?(admin)).to be true
      end

      it 'is not deletable by admin' do
        expect(board.deletable?(admin)).to be false
      end
    end

    context 'with a Public UserBoard' do
      let(:board) { create(:board, :public_user) }
      let(:admin) { create(:user, admin: true) }
      let(:stranger) { create(:user) }
      let(:member) { create(:user).tap { |u| create(:board_membership, board: board, user: u) } }

      it 'is visible to nil' do
        expect(board.visible?(nil)).to be true
      end

      it 'is not editable by member' do
        expect(board.editable?(member)).to be false
      end

      it 'is editable by owner' do
        expect(board.editable?(board.owner)).to be true
      end

      it 'is deletable by owner' do
        expect(board.deletable?(board.owner)).to be true
      end

      it 'is deletable by admin' do
        expect(board.deletable?(admin)).to be true
      end

      it 'is not deletable by member' do
        expect(board.deletable?(member)).to be false
      end
    end

    context 'with a Private UserBoard' do
      let(:board) { create(:board, :private_user) }
      let(:admin) { create(:user, admin: true) }
      let(:stranger) { create(:user) }
      let(:member) { create(:user).tap { |u| create(:board_membership, board: board, user: u) } }

      it 'is not visible to nil' do
        expect(board.visible?(nil)).to be false
      end

      it 'is not visible to stranger' do
        expect(board.visible?(stranger)).to be false
      end

      it 'is visible to member' do
        expect(board.visible?(member)).to be true
      end

      it 'is visible to owner' do
        expect(board.visible?(board.owner)).to be true
      end

      it 'is visible to admin' do
        expect(board.visible?(admin)).to be true
      end
    end
  end
end
