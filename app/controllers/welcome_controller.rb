# frozen_string_literal: true

# Handles the homepage and welcome actions.
#
# Displays the list of events on the homepage.
class WelcomeController < ApplicationController
  # Displays the homepage with all events.
  #
  # @return [void]
  def index
    @board = Board.find_by!(board_type: :top)
    @events = @board.events.order(start_date: :desc)
    render 'boards/show'
  end
end
