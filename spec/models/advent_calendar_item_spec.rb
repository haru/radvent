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
    create(:advent_calendar_item, date: 3, event: event)
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

  describe '#editable_by?' do
    let(:author) { create(:user, admin: false) }
    let(:stranger) { create(:user, admin: false) }

    context 'when the slot has an account' do
      let(:slot) { build(:advent_calendar_item, event: event, user: author, user_name: stranger.name) }

      it 'is false for a nil viewer' do
        expect(slot.editable_by?(nil)).to be false
      end

      it 'is true for the account holder' do
        expect(slot.editable_by?(author)).to be true
      end

      it 'is false for another user even when the display name matches' do
        expect(slot.editable_by?(stranger)).to be false
      end
    end

    context 'when the slot has no account' do
      let(:slot) { build(:advent_calendar_item, event: event, user: nil, user_name: author.name) }

      it 'is true when the viewer name matches the display name' do
        expect(slot.editable_by?(author)).to be true
      end

      it 'is false when the viewer name differs from the display name' do
        expect(slot.editable_by?(stranger)).to be false
      end
    end
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

    it 'returns false instead of raising when the date is out of range for the month' do
      advent_calendar_item = build(:advent_calendar_item, date: 32, event: event)
      advent_calendar_item.save(validate: false)
      create(:item, advent_calendar_item: advent_calendar_item)
      expect(advent_calendar_item.reload).not_to be_published
    end
  end

  describe 'date validity' do
    it 'is invalid without a date' do
      expect(build(:advent_calendar_item, event: event, date: nil)).not_to be_valid
    end

    it 'is invalid when the date is outside 1..31', :aggregate_failures do
      expect(build(:advent_calendar_item, event: event, date: 0)).not_to be_valid
      expect(build(:advent_calendar_item, event: event, date: 32)).not_to be_valid
    end

    it 'is valid for a date between 1 and 31' do
      expect(build(:advent_calendar_item, event: event, date: 25)).to be_valid
    end

    it 'returns false instead of raising when a legacy slot has no date' do
      slot = build(:advent_calendar_item, event: event, date: nil)
      slot.save(validate: false)
      create(:item, advent_calendar_item: slot)
      expect(slot.reload.published?).to be false
    end
  end

  describe 'date uniqueness within an event' do
    let(:other_event) do
      create(:event, name: 'other-cal', title: 'Other Calendar', start_date: '2015-12-01',
                     end_date: '2015-12-25', created_by: user, updated_by: user)
    end

    it 'is invalid when a second slot takes the same date in the same event', :aggregate_failures do
      duplicate = build(:advent_calendar_item, event: event, date: 1)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:date]).to be_present
    end

    it 'is valid when the same date is used in another event' do
      item = build(:advent_calendar_item, event: other_event, date: 1)
      expect(item).to be_valid
    end

    it 'is invalid when changing the date to a taken date' do
      slot = create(:advent_calendar_item, event: event, date: 5)
      slot.date = 1
      expect(slot).not_to be_valid
    end

    it 'is valid when a pre-existing duplicate updates fields other than date' do
      duplicate = described_class.new(event: event, date: 1, user: user, user_name: 'dup')
      duplicate.save(validate: false)
      duplicate.comment = 'updated comment'
      expect(duplicate).to be_valid
    end

    it 'is invalid when a pre-existing duplicate changes its date to a taken date' do
      create(:advent_calendar_item, event: event, date: 9)
      duplicate = described_class.new(event: event, date: 3, user: user, user_name: 'dup')
      duplicate.save(validate: false)
      duplicate.date = 9
      expect(duplicate).not_to be_valid
    end
  end
end
