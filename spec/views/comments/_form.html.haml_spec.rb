# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'comments/_form' do
  it 'clears the body field after a successful submit without rebuilding the form', :aggregate_failures do
    render partial: 'comments/form', locals: { comment: build(:comment) }
    expect(rendered).to have_css('form[data-controller="comment-form"]')
    expect(rendered).to have_css('form[data-action="turbo:submit-end->comment-form#reset"]')
  end
end
