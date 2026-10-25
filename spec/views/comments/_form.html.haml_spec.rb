# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'comments/_form' do
  it 'clears the body field after a successful submit without rebuilding the form', :aggregate_failures do
    render partial: 'comments/form', locals: { comment: build(:comment) }
    expect(rendered).to have_css('form[data-controller="comment-form"]')
    expect(rendered).to have_css('form[data-action="turbo:submit-end->comment-form#reset"]')
  end

  it 'shows the validation errors and keeps the typed values', :aggregate_failures do
    comment = build(:comment, user_name: '', body: 'typed')
    comment.validate
    render partial: 'comments/form', locals: { comment: comment }
    expect(rendered).to have_css('#comment_errors', text: Comment.human_attribute_name(:user_name))
    expect(rendered).to have_field('comment[body]', with: 'typed')
  end

  it 'renders an empty error region for a valid comment' do
    render partial: 'comments/form', locals: { comment: build(:comment) }
    expect(rendered).to have_css('#comment_errors', text: '')
  end
end
