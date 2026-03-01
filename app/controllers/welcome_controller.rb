# Handles the homepage and welcome actions.
#
# Displays the list of events on the homepage.
class WelcomeController < ApplicationController
  # Displays the homepage with all events.
  #
  # @return [void]
  def index
    @events = Event.order('start_date desc')
  end

  private
end
