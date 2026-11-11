# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LoadMorePage do
  concern = described_class

  controller(ApplicationController) do
    include concern

    def index
      page = page_number
      return if performed?

      render plain: page.to_s
    end
  end

  it 'returns the integer for a valid page of 2 or more' do
    get :index, params: { page: 3 }
    expect(response.body).to eq('3')
  end

  [nil, 'abc', '0', '1', '-4'].each do |bad|
    it "renders 422 with an empty body for page=#{bad.inspect}", :aggregate_failures do
      get :index, params: { page: bad }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to be_empty
    end
  end
end
