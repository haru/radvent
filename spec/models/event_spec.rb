# frozen_string_literal: true

require 'rails_helper'

describe Event do
  let(:user) { create(:user) }

  before do
    described_class.destroy_all
    AdventCalendarItem.destroy_all
    user
  end

  it 'returns 5 days from start_date to end_date' do
    event = build(:event, start_date: Date.parse('2019-12-01'), end_date: Date.parse('2019-12-05'))
    expect(event.day_count).to eq(5)
  end

  it 'returns 1 day for a single-day event' do
    event = build(:event, start_date: Date.parse('2019-12-01'), end_date: Date.parse('2019-12-01'))
    expect(event.day_count).to eq(1)
  end

  describe '#entry_count' do
    let(:event) { create(:event) }

    it 'returns 0 with no entries' do
      expect(event.entry_count).to eq(0)
    end

    it 'returns 1 after one entry is added' do
      create(:advent_calendar_item, event: event)
      event.reload
      expect(event.entry_count).to eq(1)
    end

    it 'returns 2 after two entries are added' do
      create(:advent_calendar_item, event: event)
      create(:advent_calendar_item, event: event)
      event.reload
      expect(event.entry_count).to eq(2)
    end
  end

  describe '#entry_percent' do
    let(:event) { create(:event, start_date: Date.parse('2019-12-01'), end_date: Date.parse('2019-12-05')) }

    it 'returns 0 with no entries' do
      expect(event.entry_percent).to eq(0)
    end

    it 'returns 20 with one entry out of five days' do
      create(:advent_calendar_item, event: event)
      event.reload
      expect(event.entry_percent).to eq(20)
    end

    it 'returns 100 when all days are filled' do
      5.times { create(:advent_calendar_item, event: event) }
      event.reload
      expect(event.entry_percent).to eq(100)
    end
  end
end
