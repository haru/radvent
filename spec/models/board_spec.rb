# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Board do
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

  describe '#member_candidates' do
    let(:board) { create(:board, :private_user) }

    def names_for(query)
      board.member_candidates(query).first.map(&:name)
    end

    it 'matches a part of the name' do
      create(:user, name: 'Yamada Taro')
      create(:user, name: 'Suzuki Hanako')
      expect(names_for('amada')).to eq ['Yamada Taro']
    end

    it 'ignores case' do
      create(:user, name: 'Yamada Taro')
      expect(names_for('YAMADA')).to eq ['Yamada Taro']
    end

    it 'matches multibyte names' do
      create(:user, name: '山田太郎')
      expect(names_for('山田')).to eq ['山田太郎']
    end

    it 'treats % as a plain character' do
      create(:user, name: '100% sure')
      create(:user, name: '100 sure')
      expect(names_for('0% s')).to eq ['100% sure']
    end

    it 'treats _ as a plain character' do
      create(:user, name: 'a_bc')
      create(:user, name: 'axbc')
      expect(names_for('a_')).to eq ['a_bc']
    end

    it 'treats the escape character ! as a plain character' do
      create(:user, name: 'wow!x')
      create(:user, name: 'wowxx')
      expect(names_for('w!x')).to eq ['wow!x']
    end

    it 'returns an empty list when nothing matches' do
      expect(board.member_candidates('zzzz')).to eq [[], false]
    end

    it 'sorts by name ascending' do
      create(:user, name: 'kk-b')
      create(:user, name: 'kk-a')
      expect(names_for('kk-')).to eq %w[kk-a kk-b]
    end

    it 'returns 10 candidates and no more flag for exactly 10 matches', :aggregate_failures do
      10.times { |i| create(:user, name: format('many-%02d', i)) }
      users, more = board.member_candidates('many-')
      expect(users.size).to eq 10
      expect(more).to be false
    end

    it 'returns the first 10 and a more flag for 11 matches', :aggregate_failures do
      10.downto(0) { |i| create(:user, name: format('many-%02d', i)) }
      users, more = board.member_candidates('many-')
      expect(users.map(&:name)).to eq((0..9).map { |i| format('many-%02d', i) })
      expect(more).to be true
    end

    it 'matches a part of the email address ignoring case' do
      create(:user, name: 'Someone', email: 'taro.yamada@example.com')
      expect(names_for('YAMADA@EXAMPLE')).to eq ['Someone']
    end

    it 'treats _ in the email term as a plain character' do
      create(:user, name: 'Under', email: 'a_b@example.com')
      create(:user, name: 'Other', email: 'axb@example.com')
      expect(names_for('a_b@')).to eq ['Under']
    end

    it 'treats % in the email term as a plain character' do
      create(:user, name: 'Percent', email: 'a%b@example.com')
      create(:user, name: 'Other', email: 'axyb@example.com')
      expect(names_for('a%b@')).to eq ['Percent']
    end

    it 'lists a user matching both name and email only once' do
      create(:user, name: 'dup-match', email: 'dup-match@example.com')
      expect(names_for('dup-match')).to eq ['dup-match']
    end

    it 'finds users matching only by name or only by email' do
      create(:user, name: 'only-name', email: 'x1@example.com')
      create(:user, name: 'Zed', email: 'only-name-mail@example.com')
      expect(names_for('only-name')).to match_array %w[Zed only-name]
    end

    it 'orders users with the same name by email' do
      create(:user, name: 'twin', email: 'b@example.com')
      create(:user, name: 'twin', email: 'a@example.com')
      expect(board.member_candidates('twin').first.map(&:email)).to eq %w[a@example.com b@example.com]
    end

    it 'excludes the board owner' do
      board.owner.update!(name: 'owner-zz')
      expect(names_for('owner-zz')).to eq []
    end

    it 'excludes existing members' do
      create(:board_membership, board: board, user: create(:user, name: 'member-zz'))
      create(:user, name: 'member-yy')
      expect(names_for('member-')).to eq ['member-yy']
    end

    it 'still lists candidates when a membership has a NULL user_id' do
      create(:board_membership, board: board).update_column(:user_id, nil) # rubocop:disable Rails/SkipsModelValidations
      create(:user, name: 'cand-zz')
      expect(names_for('cand-')).to eq ['cand-zz']
    end

    it 'does not exclude members of other boards' do
      create(:board_membership, board: create(:board, :private_user), user: create(:user, name: 'elsewhere'))
      expect(names_for('elsewhere')).to eq ['elsewhere']
    end

    it 'still lists candidates when the board has no owner' do
      board.update_column(:owner_id, nil) # rubocop:disable Rails/SkipsModelValidations
      create(:user, name: 'cand-zz')
      expect(names_for('cand-')).to eq ['cand-zz']
    end

    it 'finds a user without a name by email', :aggregate_failures do
      user = create(:user, email: 'noname@example.com')
      user.update_column(:name, nil) # rubocop:disable Rails/SkipsModelValidations
      expect(board.member_candidates('noname@').first).to eq [user]
    end

    it 'does not fail for users without a name' do
      create(:user, email: 'noname@example.com').update_column(:name, nil) # rubocop:disable Rails/SkipsModelValidations
      create(:user, name: 'nomatch-zz')
      expect(names_for('nomatch')).to eq ['nomatch-zz']
    end
  end

  # --- Delete confirmation ---
  describe '#board_id_match?' do
    let(:board) { create(:board, :public_user, board_id: 'myboard') }

    it 'returns true for an exact match' do
      expect(board.board_id_match?('myboard')).to be true
    end

    it 'returns true for input differing only in case' do
      expect(board.board_id_match?('MyBoard')).to be true
    end

    it 'returns true for input with surrounding whitespace' do
      expect(board.board_id_match?(' myboard ')).to be true
    end

    it 'returns false for a different string' do
      expect(board.board_id_match?('wrong-id')).to be false
    end

    it 'returns false for nil' do
      expect(board.board_id_match?(nil)).to be false
    end

    it 'returns false for an empty string' do
      expect(board.board_id_match?('')).to be false
    end
  end

  # --- List sort key ---
  describe '#list_sort_key' do
    let(:board) { create(:board, :public_user, created_at: Time.zone.local(2015, 11, 1)) }

    before do
      allow(Time.zone).to receive(:today).and_return(Date.new(2015, 12, 2))
    end

    context 'when the board has no events' do
      it 'returns the board created_at' do
        expect(board.list_sort_key).to eq(Time.zone.local(2015, 11, 1))
      end
    end

    context 'when the board has published items' do
      let(:event) do
        create(:event, board: board, start_date: '2015-12-01', end_date: '2015-12-25',
                       created_by: owner, updated_by: owner, created_at: Time.zone.local(2015, 11, 5))
      end
      let(:older_aci) { create(:advent_calendar_item, event: event, date: 1) }
      let(:newer_aci) { create(:advent_calendar_item, event: event, date: 2) }

      before do
        create(:item, advent_calendar_item: older_aci, updated_at: Time.zone.local(2015, 12, 1, 10, 0, 0))
        create(:item, advent_calendar_item: newer_aci, updated_at: Time.zone.local(2015, 12, 2, 9, 0, 0))
      end

      it 'returns the newest updated_at of published items' do
        expect(board.list_sort_key).to eq(Time.zone.local(2015, 12, 2, 9, 0, 0))
      end
    end

    context 'when the board has an event but no published items' do
      let(:event) do
        create(:event, board: board, start_date: '2015-12-01', end_date: '2015-12-25',
                       created_by: owner, updated_by: owner, created_at: Time.zone.local(2015, 11, 10))
      end

      it 'returns the event created_at when it has no items at all' do
        event
        expect(board.list_sort_key).to eq(Time.zone.local(2015, 11, 10))
      end

      it 'excludes items before their publish date' do
        aci = create(:advent_calendar_item, event: event, date: 25)
        create(:item, advent_calendar_item: aci, updated_at: Time.zone.local(2015, 12, 3, 0, 0, 0))
        expect(board.list_sort_key).to eq(Time.zone.local(2015, 11, 10))
      end

      it 'excludes calendar slots without an item' do
        create(:advent_calendar_item, event: event, date: 1, item: nil)
        expect(board.list_sort_key).to eq(Time.zone.local(2015, 11, 10))
      end
    end

    context 'when the board created_at is newer than the newest event and published item' do
      let(:board) { create(:board, :public_user, created_at: Time.zone.local(2015, 12, 10)) }
      let(:event) do
        create(:event, board: board, start_date: '2015-12-01', end_date: '2015-12-25',
                       created_by: owner, updated_by: owner, created_at: Time.zone.local(2015, 11, 20))
      end
      let(:aci) { create(:advent_calendar_item, event: event, date: 1) }

      before do
        create(:item, advent_calendar_item: aci, updated_at: Time.zone.local(2015, 12, 1, 10, 0, 0))
      end

      it 'returns the board created_at' do
        expect(board.list_sort_key).to eq(Time.zone.local(2015, 12, 10))
      end
    end

    context 'when the event created_at is newer than the board created_at and no published item is newer' do
      let(:event) do
        create(:event, board: board, start_date: '2015-12-01', end_date: '2015-12-25',
                       created_by: owner, updated_by: owner, created_at: Time.zone.local(2015, 12, 5))
      end
      let(:aci) { create(:advent_calendar_item, event: event, date: 1) }

      before do
        create(:item, advent_calendar_item: aci, updated_at: Time.zone.local(2015, 11, 15))
      end

      it 'returns the event created_at' do
        expect(board.list_sort_key).to eq(Time.zone.local(2015, 12, 5))
      end
    end

    context 'when a published item update is newer than both the event created_at and the board created_at' do
      let(:event) do
        create(:event, board: board, start_date: '2015-12-01', end_date: '2015-12-25',
                       created_by: owner, updated_by: owner, created_at: Time.zone.local(2015, 11, 15))
      end
      let(:aci) { create(:advent_calendar_item, event: event, date: 1) }

      before do
        create(:item, advent_calendar_item: aci, updated_at: Time.zone.local(2015, 12, 2, 12, 0, 0))
      end

      it 'returns the published item updated_at' do
        expect(board.list_sort_key).to eq(Time.zone.local(2015, 12, 2, 12, 0, 0))
      end
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
