# frozen_string_literal: true

# Creates the shared counter store for authentication rate limits.
#
# Same columns and indexes as solid_cache 1.0.10's db/cache_schema.rb, except
# that no separate cache database is provisioned: the table lives in the
# primary database so every app process counts against the same numbers
# (docs/adr/0011-*). The gem itself provides no migration for this layout.
class CreateSolidCacheEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :solid_cache_entries do |t|
      t.binary :key, limit: 1024, null: false
      t.binary :value, limit: 536_870_912, null: false
      t.datetime :created_at, null: false
      t.integer :key_hash, limit: 8, null: false
      t.integer :byte_size, limit: 4, null: false
      t.index :byte_size, name: 'index_solid_cache_entries_on_byte_size'
      t.index %i[key_hash byte_size], name: 'index_solid_cache_entries_on_key_hash_and_byte_size'
      t.index :key_hash, name: 'index_solid_cache_entries_on_key_hash', unique: true
    end
  end
end
