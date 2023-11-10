# require "image_processing/mini_magick"
require "mini_magick"

module FileOperations
  # Download and save image
  def self.download_image(file_name, url)
    file_path = "#{Rails.root}/public/#{file_name}.png"
    begin
      File.open(file_path, "wb") do |f| 
        f.write HTTParty.get(url).body
      end
      return file_path if File.file?(file_path)
    rescue => e
      Rails.logger.error "Unable to download logo image #{url}"
      return 0
    end
  end

  def self.save_thumbnail_image(original_image_path, thumbnail_file_name)
    file_path = "#{Rails.root}/public/#{thumbnail_file_name}.png"
    begin
      image = MiniMagick::Image.open(original_image_path)
      if image.width > 300 || image.height > 300
        image.resize "300 X 300"
        image.write(file_path)
      else
        actual_img = IO.binread(original_image_path)
        IO.binwrite(file_path, actual_img)
      end
      return file_path if File.file?(file_path)
    rescue => e
      Rails.logger.error "Unable to create logo thumbnail image #{file_path}"
      return 0
    end
  end
end
