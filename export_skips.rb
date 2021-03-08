#export_skips.rb

require 'dotenv'
Dotenv.load

require 'active_record'
require 'sinatra/activerecord'
require 'csv'
require 'aws-sdk-s3'
require 'sendgrid-ruby'



Dir[File.join(__dir__, 'lib', '*.rb')].each { |file| require file }
Dir[File.join(__dir__, 'models', '*.rb')].each { |file| require file }

module SkipProcess
  class Exporter
    include SendGrid

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


      mail = SendGrid::Mail.new
      mail.from = Email.new(email: 'test@example.com')
      mail.subject = 'Skip Report'
      personalization = Personalization.new
      my_emails = ENV['SENDGRID_EMAIL_LIST'].split(', ')
      my_emails.each do |mye|
        personalization.add_to(Email.new(email: mye))
        mail.add_personalization(personalization)
      end
      mail.add_content(Content.new(type: 'text/plain', value: 'See Attached CSV for Skips'))
      attachment = Attachment.new
      attachment.content = Base64.strict_encode64(skip_reason_csv)
      attachment.type = 'application/csv'
      attachment.filename = s3_filename
      attachment.disposition = 'attachment'
      attachment.content_id = 'Skip Report'
      mail.add_attachment(attachment)


      mail.reply_to = Email.new(email: 'test@example.com')
      sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
      response = sg.client.mail._('send').post(request_body: mail.to_json)
      puts response.status_code
      puts response.body
      puts response.headers

    end





  end
end