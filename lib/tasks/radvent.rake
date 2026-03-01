# frozen_string_literal: true

namespace :radvent do
  desc 'Generate radvent default settings'
  task generate_default_settings: :environment do
    config_files = %w[config/database.yml config/initializers/devise.rb]
    config_files.map { |f| File.expand_path(f, Rails.root) }.each do |file|
      unless File.exist?(file)
        FileUtils.cp("#{file}.example", file)
        puts "#{file} generated."
      end
    end
  end
end
