# frozen_string_literal: true

require 'rails_helper'

describe Comment do
  include_context 'with a board item world'

  let(:comment) { create(:comment, item: world[:item]) }

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
