require 'aws-sdk'

module AWSOperations
  def self.get_s3_client
    begin
      # TBD: Read region and credentials values from encrypted aws config file and
      # replace them with 'xyz' values below
      client = Aws::S3::Client.new(
        region: ENV.fetch('AWS_REGION'),
        credentials: Aws::Credentials.new(ENV.fetch('AWS_ACCESS_KEY_ID'), ENV.fetch('AWS_SECRET_ACCESS_KEY'))
      )
      return client
    rescue => e
      Rails.logger.error("Unable to get s3 client => #{e}")
      return 0
    end
  end

  def self.aws_s3_file_upload(s3_client, file_path, key)
    file_name = file_path.match(/.*\/(.*)$/)[1]
    key += file_name
    begin
      File.open(file_path, 'rb') do |file|
        # TBD: Read bucket value from encrypted aws config file and
        # replace them with 'xyz' value below
        s3_client.put_object(bucket: 'biosmart-ui', key: key, body: file, acl: "public-read")
      end
    rescue => e
      Rails.logger.error("Unable to upload file #{file_path} to key #{key} => #{e}")
    end
  end
end
