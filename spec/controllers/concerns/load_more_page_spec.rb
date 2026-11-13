# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LoadMorePage do
  concern = described_class

  controller(ApplicationController) do
    include concern

    before_action :require_load_more_page

    def index
      render plain: instance_variable_get(:@page).to_s
    end
  end

  it 'returns the integer for a valid page of 2 or more' do
    get :index, params: { page: 3 }
    expect(response.body).to eq('3')
  end

  [nil, 'abc', '0', '1', '-4', ' 2 ', '1_0', '0x2', '2.5'].each do |bad|
    it "renders 422 with an empty body for page=#{bad.inspect}", :aggregate_failures do
      get :index, params: { page: bad }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to be_empty
    end
  end

  it 'renders 422 for non-scalar page params', :aggregate_failures do
    get :index, params: { page: [2] }
    expect(response).to have_http_status(:unprocessable_content)
    get :index, params: { page: { a: 2 } }
    expect(response).to have_http_status(:unprocessable_content)
  end
end
