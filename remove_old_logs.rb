#remove_old_logs.rb

require 'dotenv'
Dotenv.load


require 'aws-sdk-s3'


Dir[File.join(__dir__, 'lib', '*.rb')].each { |file| require file }
Dir[File.join(__dir__, 'models', '*.rb')].each { |file| require file }

module SkipLogs
  class Remover
    

    def initialize
      
    end

    def remove_logs
        puts "Starting"

        s3 = ::Aws::S3::Resource.new(
        credentials: ::Aws::Credentials.new(
        ENV['AWS_ACCESS_KEY_ID'],
        ENV['AWS_SECRET_ACCESS_KEY']
        ),
        region: ENV['AWS_REGION']
        )

        

        s3.client.list_objects(bucket: ENV['AWS_BUCKET_NAME']).each do |response|
            puts response.contents.map(&:key)
            #grab filename returned and evaluate too date
            #Compare to last month, if so delete using key value
            my_file_name_key = response.contents.map(&:key).first.to_s
            filename_str = my_file_name_key.gsub(/_.+/i, "")
            puts filename_str
            my_date = DateTime.parse(filename_str)
            puts my_date.month
            my_current = DateTime.now
            previous_month = my_current.prev_month
            puts previous_month.month

        end




    end

  end
end