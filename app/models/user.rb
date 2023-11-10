class User < ApplicationRecord
  has_secure_password

  has_many :regions
  has_many :contests
  has_many :participations

  after_create :reset_tokens, :send_signup_email
  #after_save :account_activated, if: :saved_change_to_status
  #after_save :account_closed, if: :saved_change_to_status
  #after_save :send_password_changed_email, if: :saved_change_to_password_digest
  
  enum status: [:opened, :activated, :logged_in, :logged_out, :locked, :closed]
  enum role: [:representative, :admin]

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :organization_name, presence: true, uniqueness: true
  
  def reset_tokens
    new_code = SecureRandom.hex
    new_code_expires_at = Time.now + 10.minutes
    payload = { user_id: id, created_at: Time.now }

    #
    # jwt token is used for login and signup, in a http-only cookie
    # see application_controller.rb
    #
    
    jwt = JWT.encode payload, Rails.application.credentials.secret_key_base, 'HS256'

    update_attribute :login_code, new_code
    update_attribute :login_attempts, 0
    update_attribute :login_code_expires_at, new_code_expires_at
    update_attribute :jwt_token, jwt
  end

  def logout
    logged_out!
    reset_tokens    
  end  





  #def authenticate_with code
  #  if locked? || closed? 
  #    false
  #  elsif login_code==code
  #    if opened? 
  #      activated!
  #    else
  #      logged_in!
  #    end  
  #    true
  #  else
  #    logged_out! 
  #    increment! :login_attempts
  #    locked! if login_attempts>login_attempts_max || login_code_expires_at>Time.now
  #    false
  #  end
  #end

  def request_onetime_login_code path
    reset_tokens
    Rails.logger.info ">>>>>>>>>>> send request onetime login email >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    #r = GmailMailer.user_onetime_login_code_email self, path
    #Rails.logger.info r.inspect
  end

  def send_signup_email
    Rails.logger.info ">>>>>>>>>>> send signup email >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    #r = GmailMailer.user_signup_email self
    #Rails.logger.info r.inspect
  end  

  def account_activated
    if activated?
      Rails.logger.info ">>>>>>>>>>> send account activated email >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
      #r = GmailMailer.user_account_activated_email self
      #Rails.logger.info r.inspect
    end
  end
  
  def send_password_changed_email
    Rails.logger.info ">>>>>>>>>>> send password changed email >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    #r = GmailMailer.user_password_changed_email self
    #Rails.logger.info r.inspect
  end

  def account_closed
    if closed?
      Rails.logger.info ">>>>>>>>>>> send account closed email >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
      #r = GmailMailer.user_account_closed_email self
      #Rails.logger.info r.inspect
    end  
  end



  rails_admin do

    object_label_method do
      :get_label
    end

    list do
      field :id
      field :organization_name          
      field :email
      field :role
      field :status
      field :created_at      
    end
    edit do 
      field :organization_name          
      field :email
      field :role
      field :status
    end
    show do
      field :id
      field :organization_name
      field :email
      field :role
      field :status
      field :created_at
    end  
  end

  def get_label
    "#{ organization_name.nil? ? '' : organization_name} : #{email.nil? ? '' : email}"
  end

end
