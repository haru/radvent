# frozen_string_literal: true

require 'rails_helper'

# Shared example for the Permissionable concern.
# Each model including Permissionable must verify the full truth table.
RSpec.shared_examples 'permissionable' do |subject_name|
  let(:admin) { create(:user, admin: true) }
  let(:stranger) { create(:user) }

  subject { send(subject_name) }

  describe '#visible?' do
    context 'when board is TopBoard' do
      let(:board) { create(:board, :top) }

      it 'returns true for nil (unauthenticated)' do
        expect(subject.visible?(nil)).to be true
      end

      it 'returns true for admin' do
        expect(subject.visible?(admin)).to be true
      end
    end

    context 'when board is Public UserBoard' do
      let(:board) { create(:board, :public_user) }

      it 'returns true for nil (unauthenticated)' do
        expect(subject.visible?(nil)).to be true
      end

      it 'returns true for admin' do
        expect(subject.visible?(admin)).to be true
      end

      it 'returns true for stranger (authenticated non-member)' do
        expect(subject.visible?(stranger)).to be true
      end
    end

    context 'when board is Protected UserBoard' do
      let(:board) { create(:board, :protected_user) }

      it 'returns true for nil (unauthenticated)' do
        expect(subject.visible?(nil)).to be true
      end

      it 'returns true for stranger' do
        expect(subject.visible?(stranger)).to be true
      end
    end

    context 'when board is Private UserBoard' do
      let(:board) { create(:board, :private_user) }
      let(:member) { create(:user).tap { |u| create(:board_membership, board: board, user: u) } }

      it 'returns false for nil (unauthenticated)' do
        expect(subject.visible?(nil)).to be false
      end

      it 'returns false for stranger (authenticated non-member)' do
        expect(subject.visible?(stranger)).to be false
      end

      it 'returns true for member' do
        expect(subject.visible?(member)).to be true
      end

      it 'returns true for owner' do
        expect(subject.visible?(board.owner)).to be true
      end

      it 'returns true for admin' do
        expect(subject.visible?(admin)).to be true
      end
    end
  end

  describe '#editable?' do
    context 'when board is TopBoard' do
      let(:board) { create(:board, :top) }

      it 'returns false for nil' do
        expect(subject.editable?(nil)).to be false
      end

      it 'returns false for stranger' do
        expect(subject.editable?(stranger)).to be false
      end

      it 'returns true for admin' do
        expect(subject.editable?(admin)).to be true
      end
    end

    context 'when board is UserBoard' do
      let(:board) { create(:board, :public_user) }
      let(:member) { create(:user).tap { |u| create(:board_membership, board: board, user: u) } }

      it 'returns false for nil' do
        expect(subject.editable?(nil)).to be false
      end

      it 'returns false for stranger' do
        expect(subject.editable?(stranger)).to be false
      end

      it 'returns false for member (non-owner)' do
        expect(subject.editable?(member)).to be false
      end

      it 'returns true for owner' do
        expect(subject.editable?(board.owner)).to be true
      end

      it 'returns true for admin' do
        expect(subject.editable?(admin)).to be true
      end
    end
  end

  describe '#deletable?' do
    context 'when board is TopBoard' do
      let(:board) { create(:board, :top) }

      it 'returns false for admin (TopBoard is never deletable)' do
        expect(subject.deletable?(admin)).to be false
      end

      it 'returns false for nil' do
        expect(subject.deletable?(nil)).to be false
      end
    end

    context 'when board is UserBoard' do
      let(:board) { create(:board, :public_user) }
      let(:member) { create(:user).tap { |u| create(:board_membership, board: board, user: u) } }

      it 'returns false for nil' do
        expect(subject.deletable?(nil)).to be false
      end

      it 'returns false for stranger' do
        expect(subject.deletable?(stranger)).to be false
      end

      it 'returns false for member (non-owner)' do
        expect(subject.deletable?(member)).to be false
      end

      it 'returns true for owner' do
        expect(subject.deletable?(board.owner)).to be true
      end

      it 'returns true for admin' do
        expect(subject.deletable?(admin)).to be true
      end
    end
  end
end
