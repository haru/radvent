# frozen_string_literal: true

# Builds a board with one item and one user per role, and pins "today" to the given date.
#
# Override +visibility+, +today+ and +item_date+ to vary the scenario. +world+ maps :owner, :member,
# :author, :outsider, :admin and :item; a nil role stands for an anonymous user.
RSpec.shared_context 'with a board item world' do
  let(:visibility) { :public }
  let(:today) { Date.new(2015, 12, 5) }
  let(:item_date) { 5 }
  let(:world) do
    owner = create(:user)
    board = create(:board, visibility: visibility, owner: owner)
    member = create(:user)
    create(:board_membership, board: board, user: member)
    author = create(:user)
    event = create(:event, board: board, start_date: '2015-12-01', end_date: '2015-12-30',
                           created_by: owner, updated_by: owner)
    acitem = create(:advent_calendar_item, event: event, user: author, date: item_date)
    { owner: owner, member: member, author: author, outsider: create(:user), admin: create(:user, admin: true),
      item: create(:item, advent_calendar_item: acitem) }
  end

  before { allow(Time.zone).to receive(:today).and_return(today) }
end
