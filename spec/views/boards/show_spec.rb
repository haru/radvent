# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'boards/show' do
  let(:owner) { create(:user) }
  let(:board) { create(:board, :public_user, owner: owner) }

  before do
    assign(:board, board)
    assign(:events, [])
    allow(view).to receive_messages(current_user: nil, user_signed_in?: false)
  end

  it 'renders the board name' do
    render
    combined = rendered + view.content_for(:content).to_s + view.content_for(:jumbotron).to_s
    expect(combined).to include(board.name)
  end
end
