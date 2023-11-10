class GmailMailer < ApplicationMailer
  default from: 'prwprw1973@gmail.com'
  layout 'mailer'

  def user_signup_email user
    @user = user
    mail to: user.email, subject: '1squared: Thanks for signing up - please verify your account'
  end

  def user_onetime_login_code_email user, path='/'
  	@user = user
    @url = "#{path}?code=#{user.login_code}"
    mail to: user.email, subject: '1squared: you requested a one-time login code'
  end

  def user_account_activated_email user
    @user = user
    mail to: user.email, subject: '1squared: thanks for verifying your email address'
  end

  def user_password_changed_email user
    @user = user
    mail to: user.email, subject: '1squared: you changed your password?'
  end

  def user_account_closed_email user
    @user = user
    mail to: user.email, subject: '1squared: account closed'
  end  

end
