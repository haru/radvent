# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'boards/show', type: :view do
  let(:owner) { create(:user) }
  let(:board) { create(:board, :public_user, owner: owner) }

  before do
    assign(:board, board)
    assign(:events, [])
    allow(view).to receive(:current_user).and_return(nil)
    allow(view).to receive(:user_signed_in?).and_return(false)
  end

  it 'renders the board name' do
    render
    combined = rendered + view.content_for(:content).to_s + view.content_for(:header_bar).to_s
    expect(combined).to include(board.name)
  end

  it 'renders the breadcrumb with TOP link' do
    render
    breadcrumb = view.content_for(:header_bar).to_s
    expect(breadcrumb).to include(I18n.t('breadcrumb.top'))
  end

  it 'renders the board name in breadcrumb' do
    render
    breadcrumb = view.content_for(:header_bar).to_s
    expect(breadcrumb).to include(board.name)
  end
end
