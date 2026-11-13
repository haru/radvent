# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Item, '.search_readable' do
  let(:event) { create(:event, start_date: '2015-12-01', end_date: '2015-12-30') }

  before { allow(Time.zone).to receive(:today).and_return(Date.new(2015, 12, 10)) }

  # Creates an item on a new slot of +target_event+.
  #
  # @return [Item] the created item
  def make_item(title: 'title', body: 'body', date: 1, target_event: event, **slot_attrs)
    slot = create(:advent_calendar_item, event: target_event, date: date, **slot_attrs)
    create(:item, advent_calendar_item: slot, title: title, body: body)
  end

  def make_event(start_date: '2015-12-01', end_date: '2015-12-30', **attrs)
    create(:event, start_date: start_date, end_date: end_date, **attrs)
  end

  # Creates an event on a new private board of which +member+ is a member.
  #
  # @return [Event] the event
  def make_private_event_for(member)
    board = create(:board, :private_user)
    create(:board_membership, board: board, user: member)
    make_event(board: board)
  end

  def search(*keywords, user: nil)
    described_class.search_readable(keywords, user)
  end

  def count_queries(&)
    count = 0
    counter = ->(*, payload) { count += 1 unless %w[SCHEMA TRANSACTION].include?(payload[:name]) }
    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record', &)
    count
  end

  it 'returns item ids' do
    item = make_item(title: 'Rails')
    expect(search('rails')).to eq([item.id])
  end

  it 'matches the title alone and the body alone' do
    by_title = make_item(title: 'Rails tips', body: 'x', date: 1)
    by_body = make_item(title: 'x', body: 'about Rails', date: 2)
    make_item(title: 'x', body: 'y', date: 3)
    expect(search('Rails')).to contain_exactly(by_title.id, by_body.id)
  end

  it 'ignores case' do
    item = make_item(title: 'Rails')
    expect(search('rAILS')).to eq([item.id])
  end

  it 'does not match author or event text' do
    make_item(title: 'x', body: 'y', user_name: 'AuthorOnlyWord', target_event: make_event(title: 'EventOnlyWord'))
    expect([search('AuthorOnlyWord'), search('EventOnlyWord')]).to all(be_empty)
  end

  it 'does not match comment text' do
    create(:comment, item: make_item(title: 'x', body: 'y'), body: 'CommentOnlyWord')
    expect(search('CommentOnlyWord')).to be_empty
  end

  it 'treats % _ and ! as plain characters' do
    literal = make_item(title: '100%_off!', date: 1)
    make_item(title: '100xyoff', date: 2)
    expect(%w[% _ !].map { |keyword| search(keyword) }).to all(eq([literal.id]))
  end

  it 'treats a backslash and an escaped wildcard as plain characters', :aggregate_failures do
    literal = make_item(title: 'C:\\path a!%b', date: 1)
    make_item(title: 'Cpath axb', date: 2)
    expect([search('\\'), search(':\\p'), search('!%')]).to all(eq([literal.id]))
  end

  it 'raises ArgumentError for empty keywords' do
    expect { search }.to raise_error(ArgumentError)
  end

  it 'raises ArgumentError for a blank keyword, never returning every item', :aggregate_failures do
    make_item
    expect { search('') }.to raise_error(ArgumentError)
    expect { search('rails', ' ') }.to raise_error(ArgumentError)
  end

  it 'raises Date::Error when a matched slot has a date that does not exist in its month' do
    november = make_event(start_date: '2015-11-01', end_date: '2015-11-30')
    slot = create(:advent_calendar_item, event: november, date: 1)
    create(:item, advent_calendar_item: slot, title: 'title')
    slot.update_column(:date, 31) # rubocop:disable Rails/SkipsModelValidations
    expect { search('title') }.to raise_error(Date::Error)
  end

  it 'orders by publish date, then id, both descending, across events of the same month' do
    oldest = make_item(date: 1)
    newest = make_item(date: 5, target_event: make_event)
    same_day = make_item(date: 5)
    expect(search('title')).to eq([same_day.id, newest.id, oldest.id])
  end

  it 'orders a later month before an earlier one' do
    old = make_item(target_event: make_event(start_date: '2015-10-01', end_date: '2015-10-30'), date: 30)
    recent = make_item(date: 1)
    expect(search('title')).to eq([recent.id, old.id])
  end

  it 'tolerates a nil body' do
    item = make_item(title: 'Rails', body: nil)
    expect(search('rails')).to eq([item.id])
  end

  it 'ignores slots without an item' do
    create(:advent_calendar_item, event: event, date: 9)
    item = make_item(title: 'Rails')
    expect(search('rails')).to eq([item.id])
  end

  it 'does not query per matched item' do
    3.times { |i| make_item(date: i + 1) }
    baseline = count_queries { search('title') }
    3.times { |i| make_item(date: i + 4) }
    expect(count_queries { search('title') }).to be <= baseline
  end

  context 'with a private board' do
    let(:member) { create(:user) }
    let(:private_event) { make_private_event_for(member) }
    let(:queries) { -> { count_queries { search('title', user: member) } } }

    before { 3.times { |i| make_item(date: i + 1, target_event: private_event) } }

    it 'does not query per matched item' do
      baseline = queries.call
      3.times { |i| make_item(date: i + 4, target_event: private_event) }
      expect(queries.call).to be <= baseline
    end
  end

  context 'with multiple keywords' do
    it 'requires every keyword, in the title or the body' do
      both = make_item(title: 'Ruby', body: 'Rails', date: 1)
      make_item(title: 'Ruby', body: 'x', date: 2)
      make_item(title: 'x', body: 'Rails', date: 3)
      expect(search('Ruby', 'Rails')).to eq([both.id])
    end

    it 'supports three or more keywords' do
      three = make_item(title: 'a b', body: 'c', date: 1)
      make_item(title: 'a b', body: 'x', date: 2)
      expect(search('a', 'b', 'c')).to eq([three.id])
    end

    it 'treats a repeated keyword the same as one' do
      item = make_item(title: 'Rails')
      expect(search('rails', 'rails')).to eq([item.id])
    end
  end

  context 'with a board item world' do
    include_context 'with a board item world'

    let(:all_roles) { [nil, :admin, :owner, :member, :outsider, :author] }

    before { world }

    def found?(role, item = world[:item])
      search('title', user: role && world[role]).include?(item.id)
    end

    def found_by_roles(roles)
      roles.map { |role| found?(role) }
    end

    %i[public protected].each do |vis|
      context "when the board is #{vis}" do
        let(:visibility) { vis }

        it 'matches Item#readable? for every role' do
          expect(found_by_roles(all_roles)).to eq(all_roles.map { |r| world[:item].readable?(r && world[r]) })
        end

        it 'returns the item to every role, as a visible board must' do
          expect(found_by_roles(all_roles)).to all(be true)
        end
      end
    end

    context 'when the board is private' do
      let(:visibility) { :private }

      it 'returns the item to admin, owner and member' do
        expect(found_by_roles(%i[admin owner member])).to all(be true)
      end

      it 'hides the item from guests, outsiders and the non-member author' do
        expect(found_by_roles([nil, :outsider, :author])).to all(be false)
      end

      it 'stops returning it once the member is removed' do
        BoardMembership.where(user: world[:member]).destroy_all
        expect(found?(:member)).to be false
      end
    end

    it 'finds an item of the TOP board for everyone' do
      item = make_item(date: 2)
      expect(all_roles.map { |role| found?(role, item) }).to all(be true)
    end

    %i[public private].each do |vis|
      context "when the board is #{vis} and the publish date has not come" do
        let(:visibility) { vis }
        let(:today) { Date.new(2015, 12, 4) }

        it 'is found by nobody, including admin, owner and author' do
          expect(found_by_roles(all_roles)).to all(be false)
        end
      end
    end
  end

  describe 'performance', :performance do
    before { allow(Time.zone).to receive(:today).and_return(Date.new(2015, 12, 31)) }

    # Creates 34 events with 30 items each (1,020 items titled "Rails N") on a public board.
    #
    # @return [User] the author
    def create_thousand_items
      board = create(:board, :public_user)
      user = create(:user)
      Array.new(34) { make_event(board: board) }.each do |ev|
        30.times { |i| make_item(title: "Rails #{i}", body: 'x' * 500, date: i + 1, target_event: ev, user: user) }
      end
      user
    end

    it 'answers within 2 seconds for 1,000 items' do
      user = create_thousand_items
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      ids = search('rails', user: user)
      expect([ids.size, Process.clock_gettime(Process::CLOCK_MONOTONIC) - started]).to match([1020, be < 2])
    end
  end
end
