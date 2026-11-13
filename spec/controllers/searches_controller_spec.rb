# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchesController do
  render_views

  let(:page) { Capybara.string(response.body) }
  let(:event) { create(:event, title: 'Winter Calendar', start_date: '2015-12-01', end_date: '2015-12-30') }

  before { allow(Time.zone).to receive(:today).and_return(Date.new(2015, 12, 31)) }

  # Creates an item on a new slot of +target_event+.
  #
  # @return [Item] the created item
  def make_item(title: 'Rails', body: 'body', date: 1, target_event: event, **slot_attrs)
    slot = create(:advent_calendar_item, event: target_event, date: date, **slot_attrs)
    create(:item, advent_calendar_item: slot, title: title, body: body)
  end

  # Returns the hrefs of the result titles in a rendered body.
  #
  # @return [Array<String>] result links in display order
  def result_links(body = response.body)
    Capybara.string(body).all('.search-result-title a').pluck(:href)
  end

  # Creates +count+ matching items, 30 per event (one slot per day).
  #
  # @return [void]
  def make_items(count)
    events = Array.new((count / 30.0).ceil) { create(:event, start_date: '2015-12-01', end_date: '2015-12-30') }
    count.times { |i| make_item(title: "Rails #{i}", date: (i % 30) + 1, target_event: events[i / 30]) }
  end

  describe 'GET #index performance', :performance do
    it 'renders the first 20 of 1,020 matching items within 2 seconds' do
      make_items(1020)
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      get :index, params: { q: 'rails' }
      expect([result_links.size, Process.clock_gettime(Process::CLOCK_MONOTONIC) - started]).to match([20, be < 2])
    end
  end

  describe 'GET #index input validation' do
    it 'responds 400 with an empty body when q is an array', :aggregate_failures do
      get :index, params: { q: ['a'] }
      expect(response).to have_http_status(:bad_request)
      expect(response.body).to be_blank
    end

    it 'responds 400 when q is a hash' do
      get :index, params: { q: { a: 'b' } }
      expect(response).to have_http_status(:bad_request)
    end

    it 'sends Cache-Control no-store with the 400', :aggregate_failures do
      get :index, params: { q: ['a'] }
      expect(response).to have_http_status(:bad_request)
      expect(response.headers['Cache-Control']).to include('no-store')
    end

    [nil, '', '   ', "　　"].each do |blank|
      it "asks for a keyword when q is #{blank.inspect}", :aggregate_failures do
        make_item
        get :index, params: { q: blank }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t('search.index.blank'))
        expect(page).to have_no_css('.search-results')
      end
    end

    it 'rejects a query of 101 characters with 422 and a notice', :aggregate_failures do
      make_item(title: 'a' * 101)
      get :index, params: { q: 'a' * 101 }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(I18n.t('search.index.too_long', count: 100))
      expect(page).to have_no_css('.search-results')
    end

    it 'searches a query of exactly 100 characters' do
      make_item(title: 'a' * 100)
      get :index, params: { q: 'a' * 100 }
      expect(page).to have_css('.search-result', count: 1)
    end

    it 'counts the length in characters, not bytes', :aggregate_failures do
      get :index, params: { q: 'あ' * 100 }
      expect(response).to have_http_status(:ok)
      get :index, params: { q: 'あ' * 101 }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'counts the length after stripping surrounding whitespace' do
      get :index, params: { q: " #{'a' * 100} " }
      expect(response).to have_http_status(:ok)
    end

    it 'handles a long run of inner whitespace in linear time', :aggregate_failures do
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      get :index, params: { q: "a#{' ' * 200_000}a" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).to be < 1
    end

    it "responds 400 when q contains a control character such as NUL" do
      get :index, params: { q: "ab\u0000c" }
      expect(response).to have_http_status(:bad_request)
    end

    it 'does not require authentication' do
      get :index, params: { q: 'rails' }
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #page input validation' do
    [nil, 'abc', '0', '1', '-2'].each do |bad|
      it "responds 422 for page=#{bad.inspect}" do
        get :page, params: { q: 'rails', page: bad }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    it 'sends Cache-Control no-store with the 422 for an invalid page', :aggregate_failures do
      get :page, params: { q: 'rails', page: 'abc' }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.headers['Cache-Control']).to include('no-store')
    end

    [nil, '', '  ', 'a' * 101].each do |bad|
      it "responds 422 with an empty body for q=#{bad&.truncate(5).inspect}", :aggregate_failures do
        get :page, params: { q: bad, page: 2 }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to be_blank
      end
    end

    it 'responds 400 when q is not a string' do
      get :page, params: { q: ['a'], page: 2 }
      expect(response).to have_http_status(:bad_request)
    end

    it 'responds 400 when q contains a control character such as NUL' do
      get :page, params: { q: "ab\u0000c", page: 2 }
      expect(response).to have_http_status(:bad_request)
    end

    it 'answers an enormous page with an empty frame instead of failing', :aggregate_failures do
      make_item
      get :page, params: { q: 'rails', page: '99999999999999999999' }
      expect(response).to have_http_status(:ok)
      expect(page).to have_css('turbo-frame#search-results-page-99999999999999999999')
      expect(page).to have_no_css('.search-result')
    end
  end

  describe 'GET #index results' do
    it 'finds items by title alone and by body alone', :aggregate_failures do
      make_item(title: 'Rails guide', body: 'x', date: 1)
      make_item(title: 'x', body: 'learning rails', date: 2)
      make_item(title: 'x', body: 'y', date: 3)
      get :index, params: { q: 'rails' }
      expect(page).to have_css('.search-result', count: 2)
    end

    context 'with one result' do
      let(:item) { make_item(title: 'Rails guide', body: 'hello rails world', date: 5, user_name: 'Alice') }
      let(:result) { page.find('.search-result') }

      before do
        item
        get :index, params: { q: 'rails' }
      end

      it 'links the title to the article' do
        expect(result).to have_link('Rails guide', href: item_path(item))
      end

      it 'shows the author with the courtesy title' do
        expect(result).to have_css('.search-result-author', text: "Alice#{I18n.t('views.courtesy_title')}")
      end

      it 'shows the board and the event' do
        expect(result).to have_css('.search-result-board').and have_css('.search-result-event', text: 'Winter Calendar')
      end

      it 'shows the publish date' do
        text = I18n.t('search.result.post_date', year: 2015, month: 12, day: 5)
        expect(result).to have_css('.search-result-date', text: text)
      end

      it 'shows the excerpt' do
        expect(result).to have_css('.search-result-excerpt', text: 'hello')
      end
    end

    it 'orders by publish date descending, then id descending' do
      other = create(:event, start_date: '2015-12-01', end_date: '2015-12-30')
      items = [make_item(title: 'Rails a', date: 9), make_item(title: 'Rails b', date: 9, target_event: other),
               make_item(title: 'Rails c', date: 1)]
      get :index, params: { q: 'rails' }
      expect(result_links).to eq(items.values_at(1, 0, 2).map { |i| item_path(i) })
    end

    it 'highlights keywords in the title and the excerpt', :aggregate_failures do
      make_item(title: 'Rails guide', body: 'about Rails')
      get :index, params: { q: 'rails' }
      expect(page).to have_css('.search-result-title mark', text: 'Rails')
      expect(page).to have_css('.search-result-excerpt mark', text: 'Rails')
    end

    it 'escapes markup in the body but still shows it as text', :aggregate_failures do
      make_item(title: 'Rails', body: '<script>alert(1)</script> rails')
      get :index, params: { q: 'rails' }
      expect(response.body).not_to include('<script>alert(1)</script>')
      expect(page).to have_css('.search-result-excerpt', text: '<script>alert(1)</script>')
    end

    it 'escapes markup in the body once when only the title matched', :aggregate_failures do
      make_item(title: 'Rails', body: 'a < b & c')
      get :index, params: { q: 'rails' }
      expect(page).to have_css('.search-result-excerpt', exact_text: 'a < b & c')
      expect(response.body).not_to include('&amp;lt;')
    end

    it 'escapes markup in the title', :aggregate_failures do
      make_item(title: '<img src=x onerror=1> rails')
      get :index, params: { q: 'rails' }
      expect(page).to have_no_css('.search-result-title img')
      expect(page).to have_css('.search-result-title', text: '<img src=x onerror=1> rails')
    end

    it 'omits the excerpt for an empty body' do
      make_item(title: 'Rails', body: '')
      get :index, params: { q: 'rails' }
      expect(page).to have_no_css('.search-result-excerpt')
    end

    it 'shows the placeholder title for an item without a title', :aggregate_failures do
      make_item(title: '', body: 'rails inside')
      get :index, params: { q: 'rails' }
      expect(page).to have_css('.search-result-title a', text: I18n.t('activerecord.attributes.item.title_empty'))
    end

    it 'shows the total count' do
      make_items(3)
      get :index, params: { q: 'rails' }
      expect(page).to have_css('.search-count', text: I18n.t('search.index.count', count: 3))
    end

    it 'shows a notice and no count when nothing matches', :aggregate_failures do
      make_item(title: 'Other')
      get :index, params: { q: 'zzz' }
      expect(response.body).to include(I18n.t('search.index.no_results'))
      expect(page).to have_no_css('.search-count')
      expect(page).to have_no_css('.search-results')
    end

    it 'pages 20 results with a load-more frame for the rest', :aggregate_failures do
      make_items(25)
      get :index, params: { q: 'rails' }
      expect(page).to have_css('.search-result', count: 20)
      frame = page.find('turbo-frame#search-results-page-2')
      expect(frame).to have_link(I18n.t('search.index.load_more'), href: search_page_path(q: 'rails', page: 2))
    end

    it 'has no load-more frame for exactly 20 results' do
      make_items(20)
      get :index, params: { q: 'rails' }
      expect(page).to have_no_css('turbo-frame')
    end

    it 'keeps the stripped query in the title-bar field' do
      get :index, params: { q: '  rails  ' }
      expect(page).to have_field('q', with: 'rails')
    end

    it 'strips surrounding full-width spaces but keeps the inner whitespace' do
      get :index, params: { q: "　 Ruby 　Rails　 " }
      expect(page).to have_field('q', with: "Ruby 　Rails")
    end

    it 'keeps the typed query in the field when nothing matches' do
      get :index, params: { q: 'zzz' }
      expect(page).to have_field('q', with: 'zzz')
    end

    it 'leaves the field empty for a blank query' do
      get :index, params: { q: '' }
      expect(page).to have_field('q', with: '')
    end

    it 'keeps the typed query in the field when it is too long' do
      get :index, params: { q: 'a' * 101 }
      expect(page).to have_field('q', with: 'a' * 101)
    end

    it 'is sent with Cache-Control no-store' do
      get :index, params: { q: 'rails' }
      expect(response.headers['Cache-Control']).to include('no-store')
    end

    it 'never echoes the query unescaped', :aggregate_failures do
      get :index, params: { q: '<b>x</b>' }
      expect(response.body).not_to include('<b>x</b>')
      expect(page).to have_field('q', with: '<b>x</b>')
    end
  end

  describe 'multiple keywords' do
    before do
      make_item(title: 'Ruby', body: 'Rails', date: 1)
      make_item(title: 'Ruby', body: 'x', date: 2)
      make_item(title: 'x', body: 'Rails', date: 3)
    end

    [' ', "　", '   ', " 　 "].each do |sep|
      it "treats #{sep.inspect} as a keyword separator" do
        get :index, params: { q: "Ruby#{sep}Rails" }
        expect(page).to have_css('.search-result', count: 1)
      end
    end

    it 'ignores leading and trailing spaces' do
      get :index, params: { q: "  Ruby 　Rails  " }
      expect(page).to have_css('.search-result', count: 1)
    end

    it 'highlights every keyword', :aggregate_failures do
      get :index, params: { q: 'Ruby Rails' }
      expect(page).to have_css('.search-result-title mark', text: 'Ruby')
      expect(page).to have_css('.search-result-excerpt mark', text: 'Rails')
    end
  end

  describe 'GET #page results' do
    it 'returns the second page as a frame without layout', :aggregate_failures do
      make_items(25)
      get :page, params: { q: 'rails', page: 2 }
      expect(page).to have_css('turbo-frame#search-results-page-2 ol.search-results .search-result', count: 5)
      expect(page).to have_no_css('nav')
    end

    it 'links to the next page while results remain', :aggregate_failures do
      make_items(45)
      get :page, params: { q: 'rails', page: 2 }
      expect(page).to have_css('.search-result', count: 20)
      expect(page).to have_css('turbo-frame#search-results-page-3')
    end

    it 'has no next frame on the last page' do
      make_items(40)
      get :page, params: { q: 'rails', page: 2 }
      expect(page).to have_no_css('turbo-frame#search-results-page-3')
    end

    it 'returns an empty frame past the last page', :aggregate_failures do
      make_items(3)
      get :page, params: { q: 'rails', page: 5 }
      expect(response).to have_http_status(:ok)
      expect(page).to have_css('turbo-frame#search-results-page-5')
      expect(page).to have_no_css('ol')
    end

    it 'neither repeats nor drops items between page 1 and page 2' do
      make_items(25)
      get :index, params: { q: 'rails' }
      first = result_links
      get :page, params: { q: 'rails', page: 2 }
      expect((first + result_links).uniq.size).to eq(25)
    end
  end

  describe 'readability' do
    include_context 'with a board item world'

    before { world[:item].update!(title: 'secrettitle', body: 'secretbody') }

    def hits_for(role)
      sign_in world[role] if role
      get :index, params: { q: 'secret' }
      result_links
    end

    %i[public protected private].each do |vis|
      context "when the board is #{vis}" do
        let(:visibility) { vis }

        [nil, :outsider, :member, :owner, :admin, :author].each do |role|
          it "lists the item exactly when #{role.inspect} can read it" do
            expect(hits_for(role).include?(item_path(world[:item]))).to eq(world[:item].readable?(role && world[role]))
          end
        end
      end
    end

    context 'when the board is private and the viewer is an outsider' do
      let(:visibility) { :private }

      before do
        sign_in world[:outsider]
        get :index, params: { q: 'secret' }
      end

      it 'shows no count, only the no-results notice', :aggregate_failures do
        expect(page).to have_no_css('.search-count')
        expect(response.body).to include(I18n.t('search.index.no_results'))
      end

      it 'leaks neither the title nor the body' do
        expect(response.body).not_to match(/secrettitle|secretbody/)
      end

      it 'does not leak through the load-more page either' do
        get :page, params: { q: 'secret', page: 2 }
        expect(response.body).not_to include('secrettitle')
      end
    end

    context 'when the publish date has not come' do
      let(:today) { Date.new(2015, 12, 4) }

      %i[author admin].each do |role|
        it "hides the item even from #{role}" do
          expect(hits_for(role)).to be_empty
        end
      end
    end

    context 'when only some matches are readable' do
      let(:visibility) { :private }

      it 'counts only the readable ones', :aggregate_failures do
        sign_in world[:outsider]
        make_item(title: 'secret public', date: 1)
        get :index, params: { q: 'secret' }
        expect(page).to have_css('.search-count', text: I18n.t('search.index.count', count: 1))
        expect(response.body).not_to include('secrettitle')
      end
    end
  end

  describe 'rate limiting' do
    before { Rails.cache.clear }

    after { Rails.cache.clear }

    it 'allows 30 searches per minute and rejects the 31st with 429', :aggregate_failures do
      30.times { get :index, params: { q: 'rails' } }
      expect(response).to have_http_status(:ok)
      get :index, params: { q: 'rails' }
      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include(I18n.t('errors.too_many_requests.title'))
    end

    it 'sends Cache-Control no-store with the 429', :aggregate_failures do
      31.times { get :index, params: { q: 'rails' } }
      expect(response).to have_http_status(:too_many_requests)
      expect(response.headers['Cache-Control']).to include('no-store')
    end

    it 'shares the counter between index and page' do
      make_items(25)
      29.times { get :page, params: { q: 'rails', page: 2 } }
      get :index, params: { q: 'rails' }
      get :index, params: { q: 'rails' }
      expect(response).to have_http_status(:too_many_requests)
    end

    it 'limits guests by IP, not per user' do
      30.times { get :index, params: { q: 'rails' } }
      sign_in create(:user)
      get :index, params: { q: 'rails' }
      expect(response).to have_http_status(:too_many_requests)
    end

    it 'does not affect another IP' do
      30.times { get :index, params: { q: 'rails' } }
      request.remote_addr = '10.0.0.9'
      get :index, params: { q: 'rails' }
      expect(response).to have_http_status(:ok)
    end

    it 'answers a limited page request with an invalid page with the full 429 page, not a guessed frame',
       :aggregate_failures do
      30.times { get :index, params: { q: 'rails' } }
      get :page, params: { q: 'rails', page: 'abc' }
      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include(I18n.t('errors.too_many_requests.title'))
    end

    it 'logs a limited page request' do
      30.times { get :index, params: { q: 'rails' } }
      allow(Rails.logger).to receive(:warn)
      get :page, params: { q: 'rails', page: 3 }
      expect(Rails.logger).to have_received(:warn).with(/Rate limit exceeded: searches#page/)
    end

    it 'answers a limited page request with a notice inside its frame', :aggregate_failures do
      30.times { get :index, params: { q: 'rails' } }
      get :page, params: { q: 'rails', page: 3 }
      expect(response).to have_http_status(:too_many_requests)
      expect(page).to have_css('turbo-frame#search-results-page-3', text: I18n.t('search.rate_limited'))
    end
  end
end
