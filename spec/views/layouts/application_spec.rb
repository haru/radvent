# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'layouts/application', type: :view do
  let(:admin) { create(:user, admin: true) }
  let(:regular_user) { create(:user) }

  before do
    view.extend(ApplicationHelper) if defined?(ApplicationHelper)
    # Stub out helpers that the layout needs
    without_partial_double_verification do
      allow(view).to receive(:system_title).and_return('Test App')
      allow(view).to receive(:content_for?).and_call_original
      allow(view).to receive(:yield).and_call_original
    end
  end

  context 'when user is authenticated' do
    before do
      sign_in regular_user
      allow(view).to receive(:current_user).and_return(regular_user)
      allow(view).to receive(:user_signed_in?).and_return(true)
    end

    it 'renders the username' do
      render
      expect(rendered).to include(regular_user.name)
    end

    it 'renders マイページ link' do
      render
      expect(rendered).to include(I18n.t('menu.my_page'))
    end

    it 'renders ボード管理 link' do
      render
      expect(rendered).to include(I18n.t('menu.board_management'))
    end
  end

  context 'when user is not authenticated' do
    before do
      allow(view).to receive(:current_user).and_return(nil)
      allow(view).to receive(:user_signed_in?).and_return(false)
    end

    it 'renders sign_in link' do
      render
      expect(rendered).to include(I18n.t('menu.sign_in'))
    end

    it 'renders sign_up link' do
      render
      expect(rendered).to include(I18n.t('menu.sign_up'))
    end

    it 'does not render マイページ link' do
      render
      expect(rendered).not_to include(I18n.t('menu.my_page'))
    end
  end
end
