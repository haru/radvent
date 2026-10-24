# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'container startup script' do # rubocop:disable RSpec/DescribeClass
  let(:run_sh) { Rails.root.join('docker/run.sh').read }
  let(:dockerfile) { Rails.root.join('Dockerfile').read }
  let(:run_sh_lines) { run_sh.lines.map(&:strip) }

  it 'does not dump the environment' do
    expect(run_sh_lines).not_to include('env', 'printenv', 'export -p', 'set')
  end

  it 'does not enable shell tracing in run.sh' do
    expect(run_sh).not_to match(/set\s+-[a-z]*x|set\s+-o\s+xtrace/)
  end

  it 'does not echo secret variables' do
    echoes = run_sh_lines.grep(/\Aecho\b/)
    expect(echoes.join("\n")).not_to match(/SECRET_KEY_BASE|DB_PASSWORD/)
  end

  it 'keeps set -e' do
    expect(run_sh_lines).to include('set -e')
  end

  it 'does not run the startup script with shell tracing' do
    expect(dockerfile.lines.grep(/\A\s*(CMD|ENTRYPOINT)\b/).join).not_to match(/\s-[a-z]*x\b/)
  end

  it 'logs progress with fixed messages' do
    expect(run_sh_lines.grep(/\Aecho\b/).size).to be >= 4
  end
end
