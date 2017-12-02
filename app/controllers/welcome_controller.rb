class WelcomeController < ApplicationController
  def index
    @events = Event.order('start_date desc')
  end

  private
end
