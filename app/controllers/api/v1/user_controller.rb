module Api::V1
  class UserController < ApiController
    
    def login
      if params[:password] && params[:email]
        
        u = User.find_by_email params[:email]
        raise ApiFail.new 'no user with that email' if u.nil?

        if u.authenticate(params[:password])
          u.reset_tokens
          cookies.signed.permanent[:jwt_token] = { value: u.jwt_token, httponly: true, expires: 1.hour.from_now }
          render_success
        else
          raise ApiFail.new 'incorrect email or password'
        end

      #elsif params[:code]
      #
      #  u = User.find_by_login_code params[:code]
      #  raise ApiFail.new 'no user with that login code' if u.nil?  
      #    
      #  if u.authenticate_with(params[:code])
      #    u.reset_tokens
      #    cookies.signed.permanent[:jwt_token] = { value: u.jwt_token, httponly: true }
      #    render_success
      #  else
      #    raise ApiFail.new 'unable to log in with login code'
      #  end
            
      else
        raise ApiFail.new 'unable to log in'
      end
    end

    def logout
      get_user
      if @user
        @user.logout
        cookies.delete :jwt_token
      end
      render_success
    end

    def close_account
      get_user
      if @user
        @user.closed! 
        cookies.delete :jwt_token
      end
      render_success
    end

    # def request_onetime_login_code
    #   u = User.find_by_email params[:email]
    #   raise ApiFail.new 'no user with that email' if u.nil?
    #   u.request_onetime_login_code params[:path]
    #   render_success
    # end

  end
end 
