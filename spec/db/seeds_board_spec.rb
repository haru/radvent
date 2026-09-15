# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'db/seeds.rb' do
  context 'when the top board was already created by the migration' do
    before { create(:board, :top) }

    it 'completes without raising an error' do
      expect { load Rails.root.join('db/seeds.rb') }.not_to raise_error
    end

    it 'does not create a duplicate top board' do
      load Rails.root.join('db/seeds.rb')

      expect(Board.where(board_type: :top).count).to eq(1)
    end
  end
end
