# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'comments/create.turbo_stream' do
  let(:comment) { create(:comment) }

  before do
    allow(view).to receive(:current_user).and_return(nil)
    assign(:comment, comment)
    render
  end

  it 'appends the new comment and clears stale errors without touching the typed values', :aggregate_failures do
    expect(rendered).to have_css('turbo-stream[action="append"][target="comments_list"]', visible: :all)
    expect(rendered).to have_css('turbo-stream[action="replace"][target="comment_errors"]', visible: :all)
    expect(rendered).to have_css('turbo-stream', count: 2, visible: :all)
    expect(rendered).to include(comment.body)
  end
end
