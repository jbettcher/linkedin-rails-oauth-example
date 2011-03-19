class LoginsController < ApplicationController
  helper_method :current_user

  def show
  end

  def create
    request_token = consumer.get_request_token(:oauth_callback => callback_login_url)
    Rails.cache.write(request_token.token, request_token.secret)
    redirect_to request_token.authorize_url
  end

  def callback
    request_token = OAuth::RequestToken.new(consumer, params[:oauth_token], Rails.cache.read(params[:oauth_token]))
    access_token = request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
    session[:access_token] = access_token.token
    session[:access_token_secret] = access_token.secret
    redirect_to :action => :show
  end

  def logout
    reset_session
    redirect_to :action => :show
  end

  private
  CONSUMER_KEY = {
    :key => "YOUR KEY HERE",
    :secret => "YOUR SECRET KEY HERE"
  }
  CONSUMER_OPTIONS = { :site => 'https://api.linkedin.com',
                     :authorize_path => '/uas/oauth/authorize',
                     :request_token_path => '/uas/oauth/requestToken',
                     :access_token_path => '/uas/oauth/accessToken' }

  def consumer
    @consumer ||= OAuth::Consumer.new( CONSUMER_KEY[:key], CONSUMER_KEY[:secret], CONSUMER_OPTIONS)
  end

  def access_token
    if session[:access_token]
      @access_token ||= OAuth::AccessToken.new(consumer, session[:access_token], session[:access_token_secret])
    end
  end

  def current_user
    if access_token
      @current_user ||= JSON.parse(access_token.get('http://api.linkedin.com/v1/people/~', 'x-li-format' => 'json').body)
    end
    @current_user
  end

end
