class ApiController < ActionController::API
  include ActionController::Cookies

  before_action { request.format = :json }

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::RoutingError, with: :route_not_found
  # rescue_from ActionController::ActionControllerError, with: :controller_error
  #rescue_from Rack::Timeout::RequestTimeoutException, with: :timeout_exception
  rescue_from JWT::DecodeError, with: :jwt_error

  def record_not_found
    render json: { status: 'error', message: 'record not found' }
  end

  def route_not_found
    render json: { status: 'error', message: 'route not found' }
  end  

  def route_not_found
    render json: { status: 'error', message: 'controller error, unmatched api route' }
  end  

  def timeout_exception
  	render json: { status: 'error', message: 'timed out' }
  end

  def jwt_error
    render json: { status: 'error', message: 'unable to decode jwt token' }
  end    

  
  class ApiFail < StandardError
    attr_reader :fail_message
    def initialize fail_message
      @fail_message = fail_message
      super ""
    end
  end

  rescue_from ApiFail do |e|
    render json: { status: 'fail', message: e.fail_message }
  end

  class ApiUnauthorized < StandardError
  end  

  rescue_from ApiUnauthorized do |e|
    render json: { status: 'error', message: 'unauthorized' }, status: :unauthorized
  end



  class CustomInputType
    def self.is_valid? x
      !convert(x).nil?
    end
  end  

  class Boolean < CustomInputType
    def self.convert s
      return true if s==true || (s.is_a?(String) && s.downcase=="true")
      return false if s==false || (s.is_a?(String) && s.downcase=="false")
      nil
    end
  end

  class UnixTime < CustomInputType # 13 digit unix timestamp in milliseconds
    def self.convert s
      return nil unless s.to_i.to_s==s
      begin Time.at(s.to_i/1000).to_datetime rescue nil end
    end
  end

  class CommaSeparatedIntegers < CustomInputType
    def self.convert s
      begin s.split(',').map { |id| id.to_i } rescue nil end
    end
  end

  class CommaSeparatedStrings < CustomInputType
    def self.convert s
      begin s.split(',') rescue nil end
    end
  end




  def requires! name, opts={}
    raise ApiFail.new "parameter #{name} is required" if !params.key?(name)
    optional! name, opts
  end

  def optional! name, opts={}

    if opts[:default] && !params.key?(name)
      raise ApiFail.new "", { name: "default value '#{opts[:default]}' is not one of the allowed values #{opts[:value].join(', ')}" } if opts[:values] && !opts[:values].include?(opts[:default])
      params[name] = opts[:default]
    end

    return unless params.key?(name)

    if opts[:type]
      if opts[:type]==Integer && params[name].to_i.to_s!=params[name].to_s ||
        opts[:type]==Float && !numeric?(params[name]) ||
        opts[:type]==Boolean && !Boolean.is_valid?(params[name]) ||
        opts[:type]==Date && params[name].to_date.nil? ||
        opts[:type]==DateTime && params[name].to_datetime.nil? ||
        opts[:type]==UnixTime && !UnixTime.is_valid?(params[name]) ||
        opts[:type]==CommaSeparatedIntegers && !CommaSeparatedIntegers.is_valid?(params[name]) ||
        opts[:type]==CommaSeparatedStrings && !CommaSeparatedStrings.is_valid?(params[name])
        raise ApiFail.new "", { type: "parameter '#{name}' must be of type #{opts[:type]}" }
      end
      params[name] = params[name].to_i if opts[:type]==Integer
      params[name] = params[name].to_f if opts[:type]==Float
      params[name] = params[name].to_date if opts[:type]==Date
      params[name] = params[name].to_datetime if opts[:type]==DateTime
      params[name] = opts[:type].convert(params[name]) if [Boolean, UnixTime, CommaSeparatedIntegers, CommaSeparatedStrings].include?(opts[:type])
    end

    if !opts[:values].nil? && !opts[:values].include?(params[name].to_sym)
      raise ApiFail.new "values for parameter '#{name}' must be taken from #{opts[:values].join(', ')}"
    end
  end


  
  def index
    render_success get_object_serialized(get_model.all)
  end

  def show
      Rails.logger.info ">>>>>>>>>>>>>>>> show"
      Rails.logger.info get_model_str
      Rails.logger.info params.inspect    
    render_success get_object_serialized(get_object)
  end

  def create
    begin
      Rails.logger.info ">>>>>>>>>>>>>>>> creating"
      Rails.logger.info get_model_str
      Rails.logger.info params.inspect
      
      obj = get_model.new params[get_model_str].permit!
      Rails.logger.info "here"
      Rails.logger.info obj
      Rails.logger.info ">>>>>>>>>>>>>>>> creating"
    rescue => e
      Rails.logger.info ">>>>>> failed"
      raise ApiFail.new e.message
    end
    raise ApiFail.new obj.errors.messages unless obj.save
     Rails.logger.info ">>>>>>>>>>>>>>>> creating ok"
    render_success get_object_serialized(obj)
  end

  def update
    obj = get_object
    raise ApiFail.new obj.errors.messages unless obj.update(params[get_model_str].permit!)
    Rails.logger.info obj
    render_success get_object_serialized(obj)
  end
  
  def destroy
    obj = get_object
    obj.destroy
    render_success
  end



  protected

    @user = nil

    def get_user_no_throw
      jwt_token = cookies.signed[:jwt_token]
      @user = User.find_by_jwt_token jwt_token if jwt_token.nil?
    end  

    def get_user
      jwt_token = cookies.signed[:jwt_token]
      raise ApiUnauthorized.new if jwt_token.nil?
      @user = User.find_by_jwt_token jwt_token

#Rails.logger.info ">>>>>"
#Rails.logger.info jwt_token
#Rails.logger.info ">>>>>"
#Rails.logger.info @user.inspect
#Rails.logger.info ">>>>>"

      raise ApiUnauthorized.new if @user.nil?
      raise ApiFail.new 'this account is locked due to repeated login failures' if @user.locked?
      raise ApiFail.new 'this account is closed' if @user.closed?
    end

    def get_model
      self.class.name.gsub('Controller', '').demodulize.constantize
    end

    def get_model_str
      get_model.name.underscore
    end

    def get_serializer
      "#{get_model.name}Serializer".constantize
    end

    def get_object
      get_model.find params['id']
    end

    def get_object_serialized obj
      get_serializer.new(obj).serializable_hash[:data]
    end

    def render_success data=nil
      render json: data.nil? ? { status: 'success' } : { status: 'success', data: data }
    end

    def numeric? s
      true if Float(s) rescue false
    end

end
