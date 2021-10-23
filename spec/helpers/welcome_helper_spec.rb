require 'rails_helper'

describe WelcomeHelper do
  before do
    Item.destroy_all
    AdventCalendarItem.destroy_all
    Event.destroy_all
    @user = create(:user, admin: false)
    @event = create(:event, name: 'hogehoge', title: 'foobar', start_date: '2015-12-01', end_date: '2015-12-25', created_by: @user, updated_by: @user)
  end
  it "returns true if the date is in advent calendar's date" do
    expect(advent_calendar_date?(Date.new(2015, 12, 1), @event)).to be_truthy
  end

  it "retuns false if the date is before advent calendar's date" do
    expect(advent_calendar_date?(Date.new(2015, 11, -1), @event)).to be_falsey
  end

  it "returns false if the date is after advent calendar's date" do
    expect(advent_calendar_date?(Date.new(2015, 12, 26), @event)).to be_falsey
  end
end
