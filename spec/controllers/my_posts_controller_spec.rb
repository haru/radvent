# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MyPostsController do
  render_views

  let(:user) { create(:user) }
  let(:event) { create(:event, start_date: '2015-12-01', end_date: '2015-12-25') }
  let(:older_event) { create(:event, start_date: '2015-10-01', end_date: '2015-10-25') }
  let(:page) { Capybara.string(response.body) }

  before { allow(Time.zone).to receive(:today).and_return(Date.new(2015, 12, 2)) }

  # Creates +count+ own slots in ascending date order: the first 25 in the December event, the rest in October.
  #
  # @param count [Integer] number of slots (max 50)
  # @return [void]
  def create_slots(count)
    count.times do |i|
      slot = create(:advent_calendar_item, user: user, event: i < 25 ? event : older_event, date: (i % 25) + 1)
      create(:item, advent_calendar_item: slot, title: "Post #{i}")
    end
  end

  describe 'GET #index' do
    context 'when unauthenticated' do
      it 'redirects to the sign-in page' do
        get :index, params: { page: 2 }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when signed in' do
      before { sign_in user }

      [nil, 'abc', '0', '1'].each do |bad|
        it "responds 422 with an empty body for page=#{bad.inspect}", :aggregate_failures do
          get :index, params: { page: bad }
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to be_empty
        end
      end

      it 'renders only the remaining rows in the page-2 frame without layout', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
        create_slots(25)
        get :index, params: { page: 2 }
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include('<html')
        expect(page).to have_css('turbo-frame#my-posts-page-2')
        expect(page).to have_css('li.my-posts-item', count: 5)
        expect(page).to have_no_css('turbo-frame#my-posts-page-3')
      end

      it 'links to the next page when more rows remain', :aggregate_failures do
        create_slots(45)
        get :index, params: { page: 2 }
        expect(page).to have_css('li.my-posts-item', count: 20)
        expect(page).to have_css("turbo-frame#my-posts-page-3 a[href='#{my_posts_path(page: 3)}']")
      end

      it 'renders an empty frame beyond the last page', :aggregate_failures do
        create_slots(25)
        get :index, params: { page: 9 }
        expect(response).to have_http_status(:ok)
        expect(page).to have_css('turbo-frame#my-posts-page-9')
        expect(page).to have_no_css('li.my-posts-item')
      end

      it 'only lists the signed-in user slots', :aggregate_failures do
        create_slots(21)
        create(:advent_calendar_item, user: create(:user), event: event, date: 30)
        get :index, params: { page: 2 }
        expect(page).to have_css('li.my-posts-item', count: 1)
      end

      it 'leaves out slots on boards the user can no longer see', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
        create_slots(20)
        hidden_event = create(:event, board: create(:board, :private_user), start_date: '2015-09-01',
                                      end_date: '2015-09-25')
        create(:advent_calendar_item, user: user, event: hidden_event, date: 1)
        get :index, params: { page: 2 }
        expect(page).to have_no_css('li.my-posts-item')
      end

      it 'renders status badges and links per row', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
        allow(Time.zone).to receive(:today).and_return(Date.new(2015, 10, 2))
        create_slots(20)
        scheduled = create(:advent_calendar_item, user: user, event: older_event, date: 25)
        create(:item, advent_calendar_item: scheduled, title: 'Sched')
        get :index, params: { page: 2 }
        expect(page).to have_link('Sched', href: edit_item_path(scheduled.item))
        expect(page).to have_text(I18n.t('my_page.status.scheduled'))
      end
    end
  end
end
