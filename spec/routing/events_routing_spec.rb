# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'event routes' do
  it 'routes board-scoped show' do
    expect(get: '/boards/b1/events/ev').to route_to('events#show', board_board_id: 'b1', name: 'ev')
  end

  it 'routes board-scoped edit' do
    expect(get: '/boards/b1/events/ev/edit').to route_to('events#edit', board_board_id: 'b1', name: 'ev')
  end

  it 'routes board-scoped update (PATCH)' do
    expect(patch: '/boards/b1/events/ev').to route_to('events#update', board_board_id: 'b1', name: 'ev')
  end

  it 'routes board-scoped update (PUT)' do
    expect(put: '/boards/b1/events/ev').to route_to('events#update', board_board_id: 'b1', name: 'ev')
  end

  it 'routes board-scoped destroy' do
    expect(delete: '/boards/b1/events/ev').to route_to('events#destroy', board_board_id: 'b1', name: 'ev')
  end

  it 'keeps the name-only show route' do
    expect(get: '/events/ev').to route_to('events#show', name: 'ev')
  end

  it 'keeps the name-only edit route' do
    expect(get: '/events/ev/edit').to route_to('events#edit', name: 'ev')
  end

  it 'keeps the new route' do
    expect(get: '/events/new').to route_to('events#new')
  end

  it 'keeps the create route' do
    expect(post: '/events').to route_to('events#create')
  end

  it 'treats "new" under a board as an event name, not the new action' do
    expect(get: '/boards/b1/events/new').to route_to('events#show', board_board_id: 'b1', name: 'new')
  end

  it 'does not nest create' do
    expect(post: '/boards/b1/events').not_to be_routable
  end
end
