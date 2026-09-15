# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AddBoardToEvents migration' do
  before do
    connection = ActiveRecord::Base.connection
    connection.remove_index :events, :board_id if connection.index_exists?(:events, :board_id)
    connection.remove_column :events, :board_id
    Event.reset_column_information
  end

  after do
    Event.reset_column_information
    Board.reset_column_information
  end

  def run_migration_up!
    load Rails.root.join('db/migrate/20260304150524_add_board_to_events.rb')
    AddBoardToEvents.new.migrate(:up)
    Event.reset_column_information
    Board.reset_column_information
  end

  # events.board_id が存在しない状態を再現しているため、`belongs_to :board` の
  # association writer（内部で board_id への書き込みを試みる）を経由すると
  # ActiveModel::MissingAttributeError になる。マイグレーション適用前の実データを
  # 模すため、board を一切介さない生SQLで events 行を直接挿入する。
  def insert_legacy_event!(user)
    connection = ActiveRecord::Base.connection
    unique = SecureRandom.hex(4)
    connection.execute(<<~SQL.squish)
      INSERT INTO events (title, name, version, created_by_id, updated_by_id, created_at, updated_at)
      VALUES (#{connection.quote("Legacy Event #{unique}")}, #{connection.quote("legacy-event-#{unique}")}, 1, #{user.id}, #{user.id}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    SQL
  end

  context 'when events already exist and boards is empty' do
    before do
      user = create(:user)
      2.times { insert_legacy_event!(user) }
      Board.delete_all
    end

    it 'completes without raising an error' do
      expect { run_migration_up! }.not_to raise_error
    end

    it 'creates exactly one top board' do
      run_migration_up!

      expect(Board.where(board_type: :top).count).to eq(1)
    end

    it 'backfills board_id on every existing event to the top board' do
      run_migration_up!
      top_board = Board.find_by(board_type: :top)

      expect(Event.pluck(:board_id)).to all(eq(top_board.id))
    end
  end

  context 'when there are no events and no boards (fresh install)' do
    it 'completes without raising an error' do
      expect { run_migration_up! }.not_to raise_error
    end

    it 'creates exactly one top board' do
      run_migration_up!

      expect(Board.where(board_type: :top).count).to eq(1)
    end
  end
end
