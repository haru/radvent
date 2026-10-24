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
end
