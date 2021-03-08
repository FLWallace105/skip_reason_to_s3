require 'dotenv'
Dotenv.load
require 'active_record'
require 'sinatra/activerecord/rake'

require_relative 'export_skips'
require_relative 'remove_old_logs'




#include ActiveRecord::Tasks

#root = File.expand_path '..', __FILE__
#DatabaseTasks.env = ENV['RACK_ENV'] || 'development'
#DatabaseTasks.database_configuration = YAML.load(File.read(File.join(root, 'config/database.yml')))
#DatabaseTasks.db_dir = File.join root, 'db'
#DatabaseTasks.migrations_paths = [File.join(root, 'db/migrate')]
#DatabaseTasks.root = root

#ActiveRecord::Base.configurations = YAML.load(File.read(File.join(root, 'config/database.yml')))
#ActiveRecord::Base.establish_connection (ENV['RACK_ENV']|| 'development')&.to_sym

#load 'active_record/railties/databases.rake'

namespace :export_skip_csv do
    desc 'Export Skips to CSV'
    task :export_skip_to_date do |t|
        SkipProcess::Exporter.new.export_skips
    end
  
    
end

namespace :remove_logs do
    desc 'remove old skip_reasons logs from S3 bucket'
    task :remove_old_logs do |t|
        SkipLogs::Remover.new.remove_logs
    end


end