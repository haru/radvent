# Helper methods available in all views.
module ApplicationHelper
  # Returns the system title from environment variable or default.
  #
  # @return [String] the system title
  def system_title
    ENV['RADVENT_TITLE'] || 'Advent Calendar'
  end
end
