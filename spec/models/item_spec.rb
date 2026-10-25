# frozen_string_literal: true

require 'rails_helper'

describe Item do
  it 'retuns title value if title is not empty' do
    item = build(:item, title: 'title')
    expect(item.title).to eq('title')
  end

  it 'returns deafult value if title is empty' do
    item = build(:item, title: '')
    expect(item.title).to eq(I18n.t('activerecord.attributes.item.title_empty'))
  end

  describe '#readable?' do
    let(:all_roles) { [nil, :admin, :owner, :member, :outsider, :author] }

    include_context 'with a board item world'

    def readable_by?(role)
      world[:item].readable?(role && world[role])
    end

    %i[public protected].each do |vis|
      context "when the board is #{vis} and the publish date has come" do
        let(:visibility) { vis }

        it 'is readable by everyone' do
          expect(all_roles.map { |r| readable_by?(r) }).to all(be true)
        end
      end
    end

    context 'when the board is private and the publish date has come' do
      let(:visibility) { :private }

      it 'is readable by admin, owner and member only', :aggregate_failures do
        expect(%i[admin owner member].map { |r| readable_by?(r) }).to all(be true)
        expect([nil, :outsider, :author].map { |r| readable_by?(r) }).to all(be false)
      end
    end

    %i[public private].each do |vis|
      context "when the board is #{vis} and the publish date has not come" do
        let(:visibility) { vis }
        let(:today) { Date.new(2015, 12, 4) }

        it 'is not readable by anyone, including admin, owner and author' do
          expect(all_roles.map { |r| readable_by?(r) }).to all(be false)
        end
      end
    end
  end

  describe 'advent_calendar_item_id uniqueness' do
    let(:advent_calendar_item) { create(:advent_calendar_item) }

    it 'is invalid when the slot already has an item', :aggregate_failures do
      create(:item, advent_calendar_item: advent_calendar_item)
      duplicate = build(:item, advent_calendar_item: advent_calendar_item)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:advent_calendar_item_id]).to be_present
    end

    it 'is valid when the article belongs to a different slot' do
      create(:item, advent_calendar_item: create(:advent_calendar_item))
      item = build(:item, advent_calendar_item: advent_calendar_item)
      expect(item).to be_valid
    end
  end

  describe 'likes' do
    let(:item) { create(:item) }
    let(:alice) { create(:user, name: 'alice') }
    let(:bob) { create(:user, name: 'bob') }

    # Adds a like without validation so that legacy duplicate rows can be built.
    #
    # @param user [User] the liking user
    # @param target [Item] the liked item
    # @return [void]
    def like!(user, target = item)
      Like.new(user: user, item: target).save!(validate: false)
    end

    it 'counts zero and lists nobody without likes', :aggregate_failures do
      expect(item.like_count).to eq 0
      expect(item.liked_users).to be_empty
    end

    it 'counts each user once', :aggregate_failures do
      like!(alice)
      like!(bob)
      expect(item.like_count).to eq 2
      expect(item.liked_users.map(&:name)).to eq %w[alice bob]
    end

    it 'counts and lists a user with duplicate rows only once', :aggregate_failures do
      2.times { like!(alice) }
      expect(item.like_count).to eq 1
      expect(item.liked_users.to_a).to eq [alice]
    end

    it 'ignores likes of other items' do
      like!(alice, create(:item))
      expect(item.like_count).to eq 0
    end

    it 'still reports liked_by? from the rows' do
      like!(alice)
      expect([item.liked_by?(alice), item.liked_by?(bob), item.liked_by?(nil)]).to eq [true, false, false]
    end
  end
end
