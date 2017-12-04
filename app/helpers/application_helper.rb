module ApplicationHelper
  def system_title
    ENV['RADVENT_TITLE'] || 'Advent Calendar'
  end
end
