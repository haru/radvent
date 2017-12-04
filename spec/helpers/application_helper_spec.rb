require 'rails_helper'

describe ApplicationHelper do
  it "returns 'Advent Calendar' if RADVENT_TITLE is not setted." do
    ENV['RADVENT_TITLE'] = nil
    expect(system_title).to eq 'Advent Calendar'
  end

  it "returns 'ENV[RADVENT_TITLE]' value if RADVENT_TITLE is not setted." do
    ENV['RADVENT_TITLE'] = "test"
    expect(system_title).to eq 'test'
  end
end
