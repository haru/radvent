# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'user unlock routes' do
  it 'does not route the unlock request form' do
    expect(get: '/users/unlock/new').not_to be_routable
  end

  it 'does not route unlock requests' do
    expect(post: '/users/unlock').not_to be_routable
  end

  it 'does not route unlock tokens' do
    expect(get: '/users/unlock?unlock_token=abc').not_to be_routable
  end
end
