# frozen_string_literal: true

# Helpers to inspect the event element of the navbar breadcrumb trail in a rendered response.
module BreadcrumbHelpers
  # Returns the breadcrumb event element of the last rendered page.
  #
  # @return [Capybara::Node::Element] the breadcrumb event element
  def breadcrumb_event
    Capybara.string(response.body).find('.breadcrumb-event')
  end

  # Expects the last rendered page to show the given event title in the breadcrumb trail.
  #
  # @param title [String] the expected event title
  # @return [void]
  def expect_breadcrumb_event(title)
    expect(Capybara.string(response.body)).to have_css('.breadcrumb-event', text: title)
  end

  # Expects the last rendered page to have no event in the breadcrumb trail.
  #
  # @return [void]
  def expect_no_breadcrumb_event
    expect(Capybara.string(response.body)).to have_no_css('.breadcrumb-event')
  end
end
