require "json"

class ApplicationController < ActionController::Base
  before_action :set_meta_tags, :get_user

  def set_meta_tags
    @meta_url = ""#"https://#{Rails.application.credentials.production_domain}#{request.path}"
    @meta_type = "website"
    @meta_title = "Biosmart"
    @meta_description = ""
    @meta_image = ""#"https://#{Rails.application.credentials.production_domain}/logo.png"
    @meta_image_width = 800
    @meta_image_height = 2000
    @active_tab = nil
    @banner_messages = BannerMessage.all.where online: true
    @nobservations = 18
    file = File.open "#{Rails.root}/app/views/pages/_category_mapping.json"
    @category_mapping = JSON.load file
  end

  def get_user
    jwt_token = cookies.signed[:jwt_token]
    @user = User.find_by_jwt_token jwt_token
  end

end
