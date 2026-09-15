# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AddBoardToEvents migration' do
  # `remove_column`/`add_column` are DDL. On MySQL, DDL is not transactional and
  # implicitly commits any open transaction, so relying on `use_transactional_fixtures`
  # here would silently disable rollback (and leak rows into later specs) on that
  # adapter. Isolate this group explicitly instead of depending on DB-specific
  # transaction semantics.
  self.use_transactional_tests = false

  # The shared test schema already includes migrations that run after this one
  # (composite unique indexes on [:board_id, :title] and [:board_id, :name]),
  # and those indexes reference :board_id too. All of them must be dropped
  # before :board_id itself, and all of them must be put back afterwards, or
  # this group corrupts the schema every other spec file relies on.
  around do |example|
    connection = ActiveRecord::Base.connection
    board_id_indexes = connection.indexes(:events).select { |index| index.columns.include?('board_id') }

    board_id_indexes.each { |index| connection.remove_index :events, name: index.name }
    connection.remove_column :events, :board_id
    Event.reset_column_information

    example.run

    Event.delete_all
    Board.delete_all
    User.delete_all

    connection.remove_index :events, :board_id if connection.index_exists?(:events, :board_id)
    connection.remove_column :events, :board_id if connection.column_exists?(:events, :board_id)
    connection.add_column :events, :board_id, :integer, null: false
    board_id_indexes.each do |index|
      connection.add_index :events, index.columns, unique: index.unique, name: index.name
    end
    Event.reset_column_information
    Board.reset_column_information
  end

  def run_migration_up!
    load Rails.root.join('db/migrate/20260304150524_add_board_to_events.rb')
    AddBoardToEvents.new.migrate(:up)
    Event.reset_column_information
    Board.reset_column_information
  end

  # :board_id doesn't exist on events at this point in the test, so going
  # through the `belongs_to :board` association writer (which touches
  # board_id internally) would raise ActiveModel::MissingAttributeError.
  # Insert legacy event rows via raw SQL, bypassing Board entirely, to
  # reproduce the pre-migration production data this migration must handle.
  def insert_legacy_event!(user)
    connection = ActiveRecord::Base.connection
    unique = SecureRandom.hex(4)
    title = connection.quote("Legacy Event #{unique}")
    name = connection.quote("legacy-event-#{unique}")
    connection.execute(<<~SQL.squish)
      INSERT INTO events (title, name, version, created_by_id, updated_by_id, created_at, updated_at)
      VALUES (#{title}, #{name}, 1, #{user.id}, #{user.id}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
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
