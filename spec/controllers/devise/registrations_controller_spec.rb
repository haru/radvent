# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::RegistrationsController do # rubocop:disable RSpec/SpecFilePathFormat
  let(:user) { create(:user) }

  before { request.env['devise.mapping'] = Devise.mappings[:user] }

  describe 'GET #new' do
    render_views

    it 'keeps rendering the shared Devise sign-up view', :aggregate_failures do
      get :new
      expect(response).to have_http_status(:success)
      expect(response.body).to include('devise-bs')
    end
  end

  describe 'GET #edit' do
    context 'when rendering the view' do
      render_views
      before { sign_in user }

      it 'returns http success' do
        get :edit
        expect(response).to have_http_status(:success)
      end

      it 'renders the theme controller with the current selection' do # rubocop:disable RSpec/MultipleExpectations
        get :edit
        expect(response.body).to include('data-controller="theme"')
        system_radio = response.body[/<input[^>]*id="theme_system"[^>]*>/]
        expect(system_radio).to include('checked="checked"')
      end

      it 'passes the theme update path as a Stimulus value instead of hardcoding it in JS' do
        get :edit
        expect(response.body).to include("data-theme-path-value=\"#{theme_path}\"")
      end

      it 'associates the theme radio group with its heading for assistive technology' do
        get :edit
        expect(response.body).to match(%r{<fieldset[^>]*>.*<legend[^>]*>.*</legend>.*theme_light.*</fieldset>}m)
      end

      it 'renders the account deletion as a Turbo DELETE button with a confirmation, not a UJS link',
         :aggregate_failures do # rubocop:disable RSpec/ExampleLength
        get :edit
        page = Capybara.string(response.body)
        button = page.find_button(I18n.t('devise.registrations.edit.cancel_my_account'))
        form = button.find(:xpath, 'ancestor::form[1]')
        expect(form['action']).to eq '/users'
        expect(form).to have_css('input[name="_method"][value="delete"]', visible: :all)
        expect(button['data-turbo-confirm']).to be_present
        expect(page).to have_no_css('a[data-method="delete"]')
      end
    end
  end

  # rubocop:disable RSpec/ExampleLength
  describe 'GET #edit my posts tab' do
    render_views

    let(:today) { Date.new(2015, 12, 2) }
    let(:event) { create(:event, title: 'Winter Event', start_date: '2015-12-01', end_date: '2015-12-25') }
    let(:page) { Capybara.string(response.body) }

    before do
      allow(Time.zone).to receive(:today).and_return(today)
      sign_in user
    end

    # Creates one of the user's own slots, optionally with an article.
    #
    # @param attrs [Hash] slot attributes
    # @param title [String, nil] article title; no article is created when +false+
    # @return [AdventCalendarItem] the created slot
    def own_slot(attrs = {}, title: false)
      slot = create(:advent_calendar_item, { user: user, event: event, date: 1 }.merge(attrs))
      create(:item, advent_calendar_item: slot, title: title) unless title == false
      slot
    end

    it 'renders the two tabs with the posts tab active by default', :aggregate_failures do
      get :edit
      expect(page).to have_css('ul.nav.nav-tabs[role=tablist]')
      expect(page).to have_css('a#my-page-posts-tab.active[data-mdb-tab-init][href="#my-page-posts"]' \
                               '[aria-controls="my-page-posts"][aria-selected="true"]')
      expect(page).to have_css('a#my-page-settings-tab[data-mdb-tab-init][aria-selected="false"]:not(.active)')
      expect(page).to have_css('#my-page-posts.tab-pane.show.active')
      expect(page).to have_css('#my-page-settings.tab-pane:not(.active)', visible: :all)
    end

    it 'keeps the account form, theme and cancel button in the settings pane', :aggregate_failures do
      get :edit
      settings = page.find_by_id('my-page-settings', visible: :all)
      %w[email name password current_password].each do |field|
        expect(settings).to have_css("input[name='user[#{field}]']", visible: :all)
      end
      expect(settings).to have_css('fieldset', visible: :all)
      expect(settings).to have_button(I18n.t('devise.registrations.edit.cancel_my_account'), visible: :all)
    end

    it 'lists own slots newest first with title, board, event and date', :aggregate_failures do
      own_slot({ date: 3 }, title: 'Older in event')
      own_slot({ date: 10, event: create(:event, title: 'Autumn', start_date: '2015-10-01', end_date: '2015-10-25') },
               title: 'Autumn post')
      own_slot({ date: 20 }, title: 'Newest')
      get :edit
      titles = page.all('table.my-posts-table tbody tr').map { |row| row.find('td:first-child').text.strip }
      expect(titles).to eq(['Newest', 'Older in event', 'Autumn post'])
      first_row = page.first('table.my-posts-table tbody tr')
      expect(first_row).to have_text('Winter Event')
      expect(first_row).to have_text(ApplicationController.helpers.system_title)
      expect(first_row).to have_text('2015年12月20日')
    end

    it 'shows a placeholder for an untitled article' do
      own_slot({ date: 1 }, title: '')
      get :edit
      expect(page).to have_text(I18n.t('activerecord.attributes.item.title_empty'))
    end

    it 'never shows other users slots, even for an admin', :aggregate_failures do
      admin = create(:user, admin: true)
      sign_in admin
      create(:item, advent_calendar_item: create(:advent_calendar_item, user: user, event: event, date: 4),
                    title: 'Someone elses')
      get :edit
      expect(response.body).not_to include('Someone elses')
      expect(page).to have_no_table(class: 'my-posts-table')
    end

    it 'hides slots on a private board the user was removed from, including the event name', :aggregate_failures do
      board = create(:board, :private_user)
      private_event = create(:event, board: board, title: 'Secret Event', start_date: '2015-12-01',
                                     end_date: '2015-12-25')
      create(:item, advent_calendar_item: create(:advent_calendar_item, user: user, event: private_event, date: 1),
                    title: 'Hidden post')
      get :edit
      expect(response.body).not_to include('Secret Event')
      expect(response.body).not_to include('Hidden post')
    end

    it 'renders 20 rows and a load-more frame when there are 21 or more slots', :aggregate_failures do
      21.times { |i| own_slot({ date: i + 1 }, title: "Post #{i + 1}") }
      get :edit
      expect(page).to have_css('table.my-posts-table tbody tr', count: 20)
      expect(page).to have_css("turbo-frame#my-posts-page-2 a[href='#{my_posts_path(page: 2)}']")
    end

    it 'renders no load-more frame for 20 slots or fewer' do
      20.times { |i| own_slot({ date: i + 1 }, title: "Post #{i + 1}") }
      get :edit
      expect(page).to have_no_css('turbo-frame[id^=my-posts-page-]')
    end

    it 'shows status badges and the matching link for every status', :aggregate_failures do
      published = own_slot({ date: 1 }, title: 'Pub')
      scheduled = own_slot({ date: 20 }, title: 'Sched')
      unwritten = own_slot({ date: 25 })
      get :edit
      pub_row = page.find('tr', text: 'Pub')
      expect(pub_row).to have_text(I18n.t('my_page.status.published'))
      expect(pub_row).to have_link('Pub', href: item_path(published.item))
      expect(pub_row).to have_no_css("a[href='#{edit_item_path(published.item)}']")
      sched_row = page.find('tr', text: 'Sched')
      expect(sched_row).to have_text(I18n.t('my_page.status.scheduled'))
      expect(sched_row).to have_link('Sched', href: edit_item_path(scheduled.item))
      expect(sched_row).to have_no_css("a[href='#{item_path(scheduled.item)}']")
      unwritten_row = page.find('tr', text: I18n.t('my_page.status.unwritten'))
      expect(unwritten_row).to have_text(I18n.t('my_page.status.unwritten'))
      expect(unwritten_row).to have_link(I18n.t('my_page.write_article'),
                                         href: new_item_path(id: unwritten.id, date: unwritten.date))
    end

    it 'shows the empty state without a table when the user has no slots', :aggregate_failures do
      get :edit
      expect(page).to have_text(I18n.t('my_page.empty'))
      expect(page).to have_no_table(class: 'my-posts-table')
      expect(page).to have_no_css('turbo-frame[id^=my-posts-page-]')
    end

    it 'shows the empty state when the only slots are on an inaccessible private board', :aggregate_failures do
      board = create(:board, :private_user)
      private_event = create(:event, board: board, start_date: '2015-12-01', end_date: '2015-12-25')
      create(:advent_calendar_item, user: user, event: private_event, date: 1)
      get :edit
      expect(page).to have_text(I18n.t('my_page.empty'))
      expect(page).to have_no_table(class: 'my-posts-table')
    end

    it 'does not show the empty state when the user has a slot' do
      own_slot({ date: 1 }, title: 'x')
      get :edit
      expect(page).to have_no_text(I18n.t('my_page.empty'))
    end
  end

  # rubocop:enable RSpec/ExampleLength

  describe 'GET #edit when unauthenticated' do
    it 'redirects to the sign-in page' do
      get :edit
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'PUT #update failure re-render' do
    render_views

    let(:page) { Capybara.string(response.body) }

    before do
      sign_in user
      create(:item, advent_calendar_item: create(:advent_calendar_item, user: user, date: 1), title: 'Still listed')
      allow(Time.zone).to receive(:today).and_return(Date.new(2030, 1, 1))
      put :update, params: { user: { name: 'renamed', current_password: 'wrong-password' } }
    end

    it 'activates the settings tab and shows the errors', :aggregate_failures do
      expect(page).to have_css('a#my-page-settings-tab.active[aria-selected="true"]')
      expect(page).to have_css('a#my-page-posts-tab[aria-selected="false"]:not(.active)')
      expect(page).to have_css('#my-page-settings.show.active')
      expect(page).to have_css('#error_explanation, .alert', visible: :all)
    end

    it 'still renders the posts list in the posts pane' do
      expect(page.find_by_id('my-page-posts', visible: :all).text(:all)).to include('Still listed')
    end
  end

  describe 'DELETE #destroy' do
    before { sign_in user }

    it 'deletes the account, signs out and redirects to the top page with 303', :aggregate_failures do
      expect { delete :destroy }.to change(User, :count).by(-1)
      expect(response).to redirect_to(root_path)
      expect(response).to have_http_status(:see_other)
      expect(controller.current_user).to be_nil
    end

    it 'announces the cancellation', :aggregate_failures do
      delete :destroy
      expect(flash[:notice]).to eq I18n.t('devise.registrations.destroyed')
    end

    it 'leaves other accounts untouched' do
      other = create(:user)
      delete :destroy
      expect(User.exists?(other.id)).to be true
    end
  end

  describe 'POST #create rate limit' do
    render_views

    # Posts a registration for the nth candidate user.
    #
    # @param index [Integer] distinguishes the submitted name and address
    # @return [void]
    def register(index)
      post_registration(name: "newuser#{index}", email: "newuser#{index}@example.com", password: 'password123',
                        password_confirmation: 'password123')
    end

    # Posts a registration that fails validation.
    #
    # @return [void]
    def register_invalid
      post_registration(email: 'bad', password: 'x', password_confirmation: 'y')
    end

    # Posts the given registration attributes as a visitor who is not signed in.
    #
    # @param attributes [Hash] the submitted user attributes
    # @return [void]
    def post_registration(attributes)
      sign_out :user
      post :create, params: { user: attributes }
    end

    it 'rejects the sixth sign-up from one connection with 429 and creates no account', :aggregate_failures do
      5.times { |n| register(n) }
      expect { register(5) }.not_to(change(User, :count))
      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include(I18n.t('errors.too_many_requests.title'))
    end

    it 'keeps signing the user in while under the limit', :aggregate_failures do
      expect { register(0) }.to change(User, :count).by(1)
      expect(response).to have_http_status(:see_other).or have_http_status(:found)
      expect(controller.current_user).to be_present
    end

    it 'counts sign-ups that fail validation as attempts', :aggregate_failures do
      5.times { register_invalid }
      expect(response).to have_http_status(:unprocessable_content)
      register_invalid
      expect(response).to have_http_status(:too_many_requests)
    end

    it 'accepts sign-ups again after an hour' do
      6.times { |n| register(n) }
      travel(1.hour + 1.second) { expect { register(10) }.to change(User, :count).by(1) }
    end

    it 'does not affect another connection', :aggregate_failures do
      5.times { |n| register(n) }
      request.remote_addr = '10.4.0.1'
      expect { register(20) }.to change(User, :count).by(1)
    end

    it 'does not limit showing the sign-up form' do
      10.times { get :new }
      expect(response).to have_http_status(:success)
    end

    it 'does not limit account updates' do
      sign_in user
      10.times { put :update, params: { user: { name: 'renamed', current_password: user.password } } }
      expect(response).not_to have_http_status(:too_many_requests)
    end

    it 'does not limit account deletion' do
      sign_in user
      expect { delete :destroy }.to change(User, :count).by(-1)
    end

    it 'registers without a limit when the counter store fails' do
      allow(Rails.cache).to receive(:increment).and_return(nil)
      expect { 7.times { |n| register(n) } }.to change(User, :count).by(7)
    end
  end
end
