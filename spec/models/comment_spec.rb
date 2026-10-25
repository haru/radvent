# frozen_string_literal: true

require 'rails_helper'

describe Comment do
  include_context 'with a board item world'

  let(:comment) { create(:comment, item: world[:item]) }

  describe 'validations' do
    it 'is valid with a name and a body' do
      expect(build(:comment)).to be_valid
    end

    %i[user_name body].each do |attribute|
      ['', '   ', nil].each do |value|
        it "is invalid when #{attribute} is #{value.inspect}", :aggregate_failures do
          comment = build(:comment, attribute => value)
          expect(comment).not_to be_valid
          expect(comment.errors[attribute]).to be_present
        end
      end
    end
  end

  describe 'length limits' do
    it 'rejects a user_name over 255 characters' do
      expect(build(:comment, user_name: 'a' * 256)).not_to be_valid
    end

    it 'rejects a body over 10000 characters' do
      expect(build(:comment, body: 'a' * 10_001)).not_to be_valid
    end

    it 'accepts the maximum lengths' do
      expect(build(:comment, user_name: 'a' * 255, body: 'a' * 10_000)).to be_valid
    end
  end

  describe '#deletable?' do
    {
      nil => false, admin: true, owner: true, member: false, author: false, outsider: false
    }.each do |role, expected|
      it "is #{expected} for #{role || 'anonymous'}" do
        expect(comment.deletable?(role && world[role])).to be expected
      end
    end

    it 'is false for the owner of a different board' do
      expect(comment.deletable?(create(:board).owner)).to be false
    end
  end

  describe '#visible?' do
    context 'when the publish date has not come' do
      let(:today) { Date.new(2015, 12, 4) }

      it 'is not visible to anyone, including the admin' do
        expect([nil, :admin, :owner].map { |r| comment.visible?(r && world[r]) }).to all(be false)
      end
    end

    context 'when the board is private' do
      let(:visibility) { :private }

      it 'is visible to members only among non-admins', :aggregate_failures do
        expect(comment.visible?(world[:member])).to be true
        expect(comment.visible?(nil)).to be false
      end
    end
  end
end
