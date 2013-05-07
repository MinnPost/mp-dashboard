require 'openid/store/filesystem'
require 'omniauth/strategies/google_apps'
require 'dashing'
require './config/environments'

# General configuration
configure do
  set :auth_token, ENV['DASHING_AUTH_TOKEN']
  set :default_dashboard, 'minnpost'

  helpers do
    def protected!
     # Put any authentication code you want in here.
     # This method is run before accessing any resource.
     redirect '/auth/g' unless session[:user_id]
    end
  end
  
  use Rack::Session::Cookie
  use OmniAuth::Builder do
    provider :google_apps, :store => OpenID::Store::Filesystem.new('./tmp'), 
      :name => 'g', :domain => ENV['DASHING_OAUTH_DOMAIN']
  end

  post '/auth/g/callback' do
    if auth = request.env['omniauth.auth'] 
      session[:user_id] = auth['info']['email']
      redirect '/'
    else
      redirect '/auth/failure'
    end
  end

  get '/auth/failure' do
    'Nope.'
  end
end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

run Sinatra::Application