# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'events/show', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:event_owner) { create(:user) }
  let(:admin_user) { create(:user, admin: true) }
  let(:other_user) { create(:user) }
  let(:owned_event) do
    create(:event, name: 'owned-event', title: 'Owned Event', start_date: '2016-12-01', end_date: '2016-12-25',
                   created_by: event_owner)
  end

  context 'when user is event owner' do
    before do
      sign_in event_owner
    end

    it 'renders pencil icon' do
      get show_event_path(owned_event.name)
      expect(response.body).to include('fa-pencil-alt')
    end

    it 'links pencil icon to edit path' do
      get show_event_path(owned_event.name)
      expect(response.body).to include(edit_event_path(owned_event.name))
    end
  end

  context 'when user is admin' do
    before do
      sign_in admin_user
    end

    it 'renders pencil icon' do
      get show_event_path(owned_event.name)
      expect(response.body).to include('fa-pencil-alt')
    end

    it 'links pencil icon to edit path' do
      get show_event_path(owned_event.name)
      expect(response.body).to include(edit_event_path(owned_event.name))
    end
  end

  context 'when user is not event owner and not admin' do
    before do
      sign_in other_user
    end

    it 'does not render pencil icon' do
      get show_event_path(owned_event.name)
      expect(response.body).not_to include('fa-pencil-alt')
    end

    it 'does not link to edit path' do
      get show_event_path(owned_event.name)
      expect(response.body).not_to include(edit_event_path(owned_event.name))
    end
  end

  context 'when user is not authenticated' do
    it 'does not render pencil icon' do
      get show_event_path(owned_event.name)
      expect(response.body).not_to include('fa-pencil-alt')
    end

    it 'does not link to edit path' do
      get show_event_path(owned_event.name)
      expect(response.body).not_to include(edit_event_path(owned_event.name))
    end
  end
end
