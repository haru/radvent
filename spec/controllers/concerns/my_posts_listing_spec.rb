# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MyPostsListing do
  concern = described_class

  controller(ApplicationController) do
    include concern

    def index
      assign_my_posts(current_user, page: params[:page].to_i)
      head :ok
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
end
