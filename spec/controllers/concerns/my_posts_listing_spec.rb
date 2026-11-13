# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MyPostsListing do
  concern = described_class

  controller(ApplicationController) do
    include concern

    def index
      assign_my_posts(current_user, page: params[:page].to_i)
      head :ok
    rescue ArgumentError
      head :unprocessable_content
    end
  end

  let(:user) { create(:user) }
  let(:event) { create(:event, start_date: '2015-12-01', end_date: '2015-12-25') }

  def create_slots(count)
    other = create(:event, start_date: '2015-11-01', end_date: '2015-11-25')
    count.times do |i|
      create(:advent_calendar_item, user: user, event: i < 25 ? event : other, date: (i % 25) + 1)
    end
  end

  before { sign_in user }

  it 'uses a page size of 20' do
    expect(described_class::PAGE_SIZE).to eq(20)
  end

  it 'preloads the likes of the page items so counts need no per-row queries', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
    2.times do |i|
      slot = create(:advent_calendar_item, user: user, event: event, date: i + 1)
      item = create(:item, advent_calendar_item: slot)
      create_list(:like, i + 1, item: item)
    end
    get :index, params: { page: 1 }
    queries = 0
    callback = ->(*, payload) { queries += 1 if payload[:sql].match?(/\bSELECT\b/) }
    counts = ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
      assigns(:my_posts).map { |slot| [slot.item.like_count, slot.item.comments_count] }
    end
    expect(queries).to eq(0)
    expect(counts).to eq([[2, 0], [1, 0]])
  end

  it 'assigns the first 20 slots and the next page number for page 1 of 25', :aggregate_failures do
    create_slots(25)
    get :index, params: { page: 1 }
    expect(assigns(:my_posts).size).to eq(20)
    expect(assigns(:my_posts_next_page)).to eq(2)
  end

  it 'assigns the remaining 5 slots and no next page for page 2', :aggregate_failures do
    create_slots(25)
    get :index, params: { page: 2 }
    expect(assigns(:my_posts).size).to eq(5)
    expect(assigns(:my_posts_next_page)).to be_nil
  end

  it 'assigns an empty list and no next page beyond the last page', :aggregate_failures do
    create_slots(25)
    get :index, params: { page: 3 }
    expect(assigns(:my_posts)).to eq([])
    expect(assigns(:my_posts_next_page)).to be_nil
  end

  it 'has no next page when there are exactly 20 slots', :aggregate_failures do
    create_slots(20)
    get :index, params: { page: 1 }
    expect(assigns(:my_posts).size).to eq(20)
    expect(assigns(:my_posts_next_page)).to be_nil
  end

  it 'lists every slot exactly once, in order, across consecutive pages' do # rubocop:disable RSpec/ExampleLength
    create_slots(45)
    pages = (1..3).map do |page|
      get :index, params: { page: page }
      assigns(:my_posts)
    end
    expect(pages.flatten).to eq(AdventCalendarItem.posts_of(user))
  end

  it 'has no next page when the slots beyond the first 20 are on an inaccessible board', # rubocop:disable RSpec/ExampleLength
     :aggregate_failures do
    create_slots(20)
    private_event = create(:event, board: create(:board, :private_user), start_date: '2015-12-01',
                                   end_date: '2015-12-25')
    create(:advent_calendar_item, user: user, event: private_event, date: 1)
    get :index, params: { page: 1 }
    expect(assigns(:my_posts).size).to eq(20)
    expect(assigns(:my_posts_next_page)).to be_nil
  end

  it 'assigns an empty list for a page number too large to slice with', :aggregate_failures do
    create_slots(5)
    get :index, params: { page: 10**30 }
    expect(response).to have_http_status(:ok)
    expect(assigns(:my_posts)).to eq([])
  end

  it 'rejects a page below 1 instead of wrapping around', :aggregate_failures do
    create_slots(25)
    get :index, params: { page: 0 }
    expect(response).to have_http_status(:unprocessable_content)
    expect(assigns(:my_posts)).to be_nil
  end
end
