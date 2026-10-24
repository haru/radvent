# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Like do
  let(:user) { create(:user) }
  let(:item) { create(:item) }

  describe 'uniqueness on create' do
    it 'rejects a second like of the same item by the same user', :aggregate_failures do
      described_class.create!(user: user, item: item)
      duplicate = described_class.new(user: user, item: item)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end

    it 'accepts the same item liked by another user' do
      described_class.create!(user: user, item: item)
      expect(described_class.new(user: create(:user), item: item)).to be_valid
    end

    it 'accepts the same user liking another item' do
      described_class.create!(user: user, item: item)
      expect(described_class.new(user: user, item: create(:item))).to be_valid
    end
  end

  describe 'existing duplicate rows' do
    it 'can still be saved after an update of another attribute' do
      like = described_class.create!(user: user, item: item)
      described_class.new(user: user, item: item).save!(validate: false)
      expect(like.update(updated_at: 1.day.from_now)).to be true
    end
  end
end
