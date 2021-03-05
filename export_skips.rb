#export_skips.rb

require 'dotenv'
Dotenv.load

require 'active_record'
require 'sinatra/activerecord'
require 'csv'
require 'aws-sdk-s3'



Dir[File.join(__dir__, 'lib', '*.rb')].each { |file| require file }
Dir[File.join(__dir__, 'models', '*.rb')].each { |file| require file }

module SkipProcess
  class Exporter
    

    def initialize
      
    end

    def export_skips
        puts "Starting Export of Skips"
        #File.delete('skip_reasons.csv') if File.exist?('skip_reasons.csv')

        column_header = ["number_skips", "reasons"]
        #CSV.open('skip_reasons.csv','a+', :write_headers=> true, :headers => column_header) do |hdr|
        #    column_header = nil

        skip_reason_csv = CSV.generate do |csv|
            csv << column_header
        

        last_day_previous_month = Date.today.beginning_of_month - 1
        #puts "last_day_previous_month = #{last_day_previous_month.strftime("%Y-%m-%d")}"
        this_month_end = Date.today.end_of_month
        #puts "this_month_end = #{this_month_end.strftime("%Y-%m-%d")}"
        my_sql_skip = "select count(distinct subscription_id) from skip_reasons where created_at > \'#{last_day_previous_month.strftime("%Y-%m-%d")}\' and created_at < \'#{this_month_end.strftime("%Y-%m-%d")}\' "
        

        skip_totals = ActiveRecord::Base.connection.execute(my_sql_skip).values
        puts skip_totals.flatten.inspect

        skip_totals_value = skip_totals.flatten.first
        puts skip_totals_value

        csv_data_out = ["total_skips",  skip_totals_value]
        csv << csv_data_out
        csv_data_out = []
        csv << csv_data_out
        csv_data_out = ["Skip Reasons Details"]
        csv << csv_data_out

        my_sql_skip_reasons = "select count(distinct subscription_id), reason from skip_reasons where created_at > \'#{last_day_previous_month.strftime("%Y-%m-%d")}\' and created_at < \'#{this_month_end.strftime("%Y-%m-%d")}\' group by reason order by count(distinct subscription_id) desc"

        my_skip_reasons_totals = ActiveRecord::Base.connection.execute(my_sql_skip_reasons).values
        puts my_skip_reasons_totals.inspect
        my_skip_reasons_totals.each do |myskt|
            puts myskt.inspect
            csv <<  myskt
        end

    #end CSV loop    
    end
    puts skip_reason_csv.inspect

    s3 = ::Aws::S3::Resource.new(
      credentials: ::Aws::Credentials.new(
        ENV['AWS_ACCESS_KEY_ID'],
        ENV['AWS_SECRET_ACCESS_KEY']
      ),
      region: ENV['AWS_REGION']
    )

    s3_filename = "#{Time.now.to_formatted_s(:db)}_skip_reasons.csv"

    s3.client.put_object(
      {
        bucket: ENV['AWS_BUCKET_NAME'],
        key: s3_filename,
        body: skip_reason_csv
      }
    )

    end





  end
end