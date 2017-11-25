require 'rails_helper'

describe AdventCalendarItem do
  before do
    @event = create(:event, name: 'hogehoge', title: 'foobar', start_date: '2015-12-01', end_date: '2015-12-25', created_by: @user, updated_by: @user)
    @advent_calendar_item1 = create(:advent_calendar_item, date: 1, event: @event)
    @item1 = @advent_calendar_item1.item
    @advent_calendar_item2 = create(:advent_calendar_item, date: 2, event: @event)
    @item2 = @advent_calendar_item2.item
  end
  it "returns previous advent_calendar_item which has Item" do
    expect(AdventCalendarItem.prev(@advent_calendar_item2).first.date).to equal(1)
  end

  it "returns next advent_calendar_item which has Item" do
    create(:advent_calendar_item, date: 2, event: @event)
    expect(AdventCalendarItem.next(@advent_calendar_item1).first.date).to equal(2)
  end

  it "returns nil if there are no previous advent_calendar_item" do
    expect(AdventCalendarItem.prev(@advent_calendar_item1).first).to be_nil
  end

  it "returns nil if there are no previous advent_calendar_item which has Item" do
    @advent_calendar_item1.item = nil
    expect(AdventCalendarItem.prev(@advent_calendar_item2).first).to be_nil
  end

  it "returns nil if there are no next advent_calendar_item" do
    expect(AdventCalendarItem.next(@advent_calendar_item2).first).to be_nil
  end

  it "returns nil if there are no next advent_calendar_item which have Item" do
    @advent_calendar_item2.item = nil
    expect(AdventCalendarItem.next(@advent_calendar_item1).first).to be_nil
  end

  describe "#published?" do
    before :each do
      today = Date.new(2015, 12, 1)
      allow(Time.zone).to receive(:today).and_return(today)
    end

    it "returns true if it has an item and it's date is passed" do
      advent_calendar_item = build(:advent_calendar_item, date:1, event: @event)
      expect(advent_calendar_item.published?).to be_truthy
    end

    it "returns false if it doesn't have an item" do
      advent_calendar_item = build(:advent_calendar_item, date: 1, item:nil, event: @event)
      expect(advent_calendar_item.published?).to be_falsey
    end

    it "returns false if it's date isn't passed" do
      advent_calendar_item = build(:advent_calendar_item, date:2, event: @event)
      expect(advent_calendar_item.published?).to be_falsey
    end
  end
end
