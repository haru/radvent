# frozen_string_literal: true

require 'rails_helper'

describe AdventCalendarItem do
  let(:user) { create(:user, admin: false) }
  let(:event) do
    create(:event, name: 'hogehoge', title: 'foobar', start_date: '2015-12-01', end_date: '2015-12-25',
                   created_by: user, updated_by: user)
  end
  let(:first_advent_calendar_item) { create(:advent_calendar_item, date: 1, event: event) }
  let(:second_advent_calendar_item) { create(:advent_calendar_item, date: 2, event: event) }
  let(:first_item) { create(:item, advent_calendar_item: first_advent_calendar_item) }
  let(:second_item) { create(:item, advent_calendar_item: second_advent_calendar_item) }

  before do
    Item.destroy_all
    described_class.destroy_all
    Event.destroy_all
    User.destroy_all
    first_item
    second_item
  end

  it 'returns previous advent_calendar_item which has Item' do
    expect(described_class.prev(second_advent_calendar_item).first.date).to equal(1)
  end

  it 'returns next advent_calendar_item which has Item' do
    create(:advent_calendar_item, date: 2, event: event)
    expect(described_class.next(first_advent_calendar_item).first.date).to equal(2)
  end

  it 'returns nil if there are no previous advent_calendar_item' do
    expect(described_class.prev(first_advent_calendar_item).first).to be_nil
  end

  it 'returns nil if there are no previous advent_calendar_item which has Item' do
    first_advent_calendar_item.item = nil
    expect(described_class.prev(second_advent_calendar_item).first).to be_nil
  end

  it 'returns nil if there are no next advent_calendar_item' do
    expect(described_class.next(second_advent_calendar_item).first).to be_nil
  end

  it 'returns nil if there are no next advent_calendar_item which have Item' do
    second_advent_calendar_item.item = nil
    expect(described_class.next(first_advent_calendar_item).first).to be_nil
  end

  describe '#published?' do
    before do
      today = Date.new(2015, 12, 1)
      allow(Time.zone).to receive(:today).and_return(today)
    end

    it "returns true if it has an item and it's date is passed" do
      expect(first_advent_calendar_item).to be_published
    end

    it "returns false if it doesn't have an item" do
      advent_calendar_item = build(:advent_calendar_item, date: 1, item: nil, event: event)
      expect(advent_calendar_item).not_to be_published
    end

    it "returns false if it's date isn't passed" do
      advent_calendar_item = build(:advent_calendar_item, date: 2, event: event)
      expect(advent_calendar_item).not_to be_published
    end
  end
end
