# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BoardMembership do
  let(:user_board) { create(:board, :public_user) }
  let(:user) { create(:user) }

  describe 'associations' do
    it 'belongs to board' do
      membership = create(:board_membership, board: user_board, user: user)
      expect(membership.board).to eq(user_board)
    end

    it 'belongs to user' do
      membership = create(:board_membership, board: user_board, user: user)
      expect(membership.user).to eq(user)
    end
  end

  describe 'validations' do
    describe 'uniqueness' do
      it 'is invalid with duplicate [board_id, user_id]' do
        create(:board_membership, board: user_board, user: user)
        duplicate = build(:board_membership, board: user_board, user: user)
        expect(duplicate).not_to be_valid
      end

      it 'is valid with same user on different boards' do
        other_board = create(:board, :public_user)
        create(:board_membership, board: user_board, user: user)
        membership = build(:board_membership, board: other_board, user: user)
        expect(membership).to be_valid
      end
    end

    describe 'board must be user-type' do
      it 'is invalid when board is TopBoard' do
        top_board = create(:board, :top)
        membership = build(:board_membership, board: top_board, user: user)
        expect(membership).not_to be_valid
      end

      it 'is valid when board is a UserBoard' do
        membership = build(:board_membership, board: user_board, user: user)
        expect(membership).to be_valid
      end
    end
  end
end
