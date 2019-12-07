require 'rails_helper'

describe Event do
  before do
    Event.destroy_all
    AdventCalendarItem.destroy_all
    @user = create(:user)
  end

  it "retuns days from start_date to end_date" do
    event = build(:event, start_date: Date.parse('2019-12-01'), end_date: Date.parse('2019-12-05'))
    expect(event.day_count).to eq(5)
    event = build(:event, start_date: Date.parse('2019-12-01'), end_date: Date.parse('2019-12-01'))
    expect(event.day_count).to eq(1)
  end

  it "retuns entry_count" do
    event = create(:event)
    expect(event.entry_count).to eq(0)
    create(:advent_calendar_item, event: event)
    event.reload
    expect(event.entry_count).to eq(1)
    create(:advent_calendar_item, event: event)
    event.reload
    expect(event.entry_count).to eq(2)
  end

  it "returns entry_percent" do
    event = create(:event, start_date: Date.parse('2019-12-01'), end_date: Date.parse('2019-12-05'))
    expect(event.entry_percent).to eq(0)
    create(:advent_calendar_item, event: event)
    event.reload
    expect(event.entry_percent).to eq(20)
    create(:advent_calendar_item, event: event)
    create(:advent_calendar_item, event: event)
    create(:advent_calendar_item, event: event)
    create(:advent_calendar_item, event: event)
    event.reload
    expect(event.entry_percent).to eq(100)
  end
end
