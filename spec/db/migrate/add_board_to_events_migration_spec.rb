# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AddBoardToEvents migration' do
  # `remove_column`/`add_column` are DDL. On MySQL, DDL is not transactional and
  # implicitly commits any open transaction, so relying on `use_transactional_fixtures`
  # here would silently disable rollback (and leak rows into later specs) on that
  # adapter. Isolate this group explicitly instead of depending on DB-specific
  # transaction semantics.
  self.use_transactional_tests = false

  before do
    connection = ActiveRecord::Base.connection
    connection.remove_index :events, :board_id if connection.index_exists?(:events, :board_id)
    connection.remove_column :events, :board_id
    Event.reset_column_information
  end

  after do
    Event.delete_all
    Board.delete_all
    User.delete_all
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

  context 'when a top board already exists before the migration runs' do
    let!(:existing_top_board) { create(:board, :top) }

    before do
      user = create(:user)
      2.times { insert_legacy_event!(user) }
    end

    it 'completes without raising an error' do
      expect { run_migration_up! }.not_to raise_error
    end

    it 'does not create a duplicate top board' do
      run_migration_up!

      expect(Board.where(board_type: :top).count).to eq(1)
    end

    it 'backfills events onto the pre-existing top board instead of a new one' do
      run_migration_up!

      expect(Event.pluck(:board_id)).to all(eq(existing_top_board.id))
    end
  end
end
