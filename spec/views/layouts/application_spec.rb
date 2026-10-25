# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'layouts/application' do
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
      allow(view).to receive_messages(current_user: regular_user, user_signed_in?: true)
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

    it "renders a theme meta tag with the user's theme" do
      regular_user.update!(theme: 'dark')
      render
      expect(Capybara.string(rendered).find('meta[name="theme"]', visible: false)[:content]).to eq('dark')
    end
  end

  context 'when user is not authenticated' do
    before do
      allow(view).to receive_messages(current_user: nil, user_signed_in?: false)
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

    it 'renders a theme meta tag falling back to system' do
      render
      expect(Capybara.string(rendered).find('meta[name="theme"]', visible: false)[:content]).to eq('system')
    end
  end

  describe 'breadcrumb trail' do
    let(:owner) { create(:user) }
    let(:top_board) { Board.find_or_create_by!(board_type: :top) { |b| b.name = 'TOP' } }
    let(:user_board) { create(:board, :public_user, owner: owner, name: 'User Board Name') }
    let(:event) do
      create(:event, board: user_board, name: 'cal', title: 'Event Title', start_date: '2015-12-01',
                     end_date: '2015-12-25', created_by: owner, updated_by: owner)
    end
    let(:top_event) do
      create(:event, board: top_board, name: 'top-cal', title: 'Top Event Title', start_date: '2015-12-01',
                     end_date: '2015-12-25', created_by: owner, updated_by: owner)
    end

    before do
      allow(view).to receive_messages(current_user: nil, user_signed_in?: false, current_page?: false)
    end

    # Renders the layout once and returns the parsed document.
    #
    # @return [Capybara::Node::Document] the rendered layout
    def rendered_layout
      @rendered_layout ||= Capybara.string(render)
    end

    # Returns the event element of the breadcrumb trail.
    #
    # @return [Capybara::Node::Element] the breadcrumb event element
    def breadcrumb_event
      rendered_layout.find('.breadcrumb-event')
    end

    context 'when there is no board and no event' do
      before do
        assign(:board, nil)
        assign(:breadcrumb_event, nil)
      end

      it 'renders only the TOP link', :aggregate_failures do
        expect(rendered_layout).to have_link('TOP', href: '/')
        expect(rendered_layout).to have_no_css('.breadcrumb-event')
      end
    end

    context 'when on a user board without an event' do
      before do
        assign(:board, user_board)
        assign(:breadcrumb_event, nil)
      end

      it 'renders TOP / board name without an event element', :aggregate_failures do
        expect(rendered_layout).to have_link('User Board Name', href: "/boards/#{user_board.board_id}")
        expect(rendered_layout).to have_no_css('.breadcrumb-event')
      end
    end

    context 'when the board is unsaved with a malformed board_id' do
      before do
        assign(:board, Board.new(board_type: :user, board_id: 'Bad ID!', name: 'Draft'))
        assign(:breadcrumb_event, nil)
      end

      it 'renders no board link instead of failing to build its path' do
        expect(rendered_layout).to have_no_link('Draft')
      end
    end

    context 'when a saved board has a malformed board_id in memory' do
      before do
        user_board.board_id = 'Bad ID!'
        assign(:board, user_board)
        assign(:breadcrumb_event, nil)
      end

      it 'links to the stored board_id' do
        expect(rendered_layout).to have_link('User Board Name', href: "/boards/#{user_board.board_id_in_database}")
      end
    end

    context 'when a top board event is given' do
      before do
        assign(:board, top_board)
        assign(:breadcrumb_event, top_event)
      end

      it 'renders TOP / event title as a link to the name-only URL', :aggregate_failures do
        expect(breadcrumb_event.tag_name).to eq 'a'
        expect(breadcrumb_event[:href]).to eq '/events/top-cal'
        expect(breadcrumb_event.text).to eq 'Top Event Title'
        expect(breadcrumb_event[:title]).to eq 'Top Event Title'
      end

      it 'renders no board link for a TOP board event', :aggregate_failures do
        expect(rendered_layout).to have_link('TOP', href: '/')
        expect(rendered_layout).to have_no_link('User Board Name')
      end
    end

    context 'when a user board event is given' do
      before do
        assign(:board, user_board)
        assign(:breadcrumb_event, event)
      end

      it 'renders the board-scoped link with the full text in the title attribute',
         :aggregate_failures do
        expect(breadcrumb_event[:href]).to eq "/boards/#{user_board.board_id}/events/cal"
        expect(breadcrumb_event[:title]).to eq 'Event Title'
        expect(rendered_layout).to have_css('span.px-2', text: '/', count: 2)
      end

      it 'orders the event title after TOP and the board name', :aggregate_failures do
        html = rendered_layout.find('nav#top-menu').native.to_html
        expect(html.index('TOP')).to be < html.index('User Board Name')
        expect(html.index('User Board Name')).to be < html.index('Event Title')
      end
    end

    context 'when the current page is the event calendar' do
      before do
        allow(view).to receive(:current_page?).and_return(true)
        assign(:board, user_board)
        assign(:breadcrumb_event, event)
      end

      it 'shows the event title as the current location without a link', :aggregate_failures do
        expect(breadcrumb_event.tag_name).to eq 'span'
        expect(breadcrumb_event[:'aria-current']).to eq 'page'
        expect(breadcrumb_event.text).to eq 'Event Title'
        expect(rendered_layout).to have_no_link('Event Title')
      end
    end

    context 'when the event title contains HTML-like text' do
      let(:script_event) do
        create(:event, board: top_board, name: 'script-cal', title: '<script>bad()</script>',
                       start_date: '2015-12-01', end_date: '2015-12-25', created_by: owner, updated_by: owner)
      end

      before do
        assign(:board, top_board)
        assign(:breadcrumb_event, script_event)
      end

      it 'renders it as text, not markup', :aggregate_failures do
        expect(breadcrumb_event.text).to eq '<script>bad()</script>'
        expect(breadcrumb_event[:title]).to eq '<script>bad()</script>'
        expect(rendered).to include('&lt;script&gt;')
        expect(rendered_layout).to have_no_selector('script')
      end
    end
  end
end
