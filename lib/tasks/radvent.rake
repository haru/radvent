namespace :radvent do
  desc 'Generate radvent default settings'
  task :generate_default_settings do
    config_files = %w(config/database.yml config/initializers/devise.rb config/secrets.yml)
    config_files.map { |f| File.expand_path(f, Rails.root) }.each do |file|
      unless File.exist?(file)
        FileUtils.cp("#{file}.example", file)
        puts "#{file} generated."
      end
    end
  end
end
