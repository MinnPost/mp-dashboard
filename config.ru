require 'openid/store/filesystem'
require 'omniauth/strategies/google_apps'
require 'dashing'
require 'sinatra/activerecord'

# Enironment specific configuration
configure :development, :test do
  set :database, 'sqlite:///development.db'
end
 
configure :production do
  # Database connection
  db = URI.parse(ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
 
  ActiveRecord::Base.establish_connection(
    :adapter  => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
    :host     => db.host,
    :username => db.user,
    :password => db.password,
    :database => db.path[1..-1],
    :encoding => 'utf8'
  )
end

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