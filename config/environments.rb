require 'dashing'
require 'sinatra/activerecord'

# Enironment specific configuration
configure :development, :test do
  set :database, 'sqlite:///development.db'
end
 
configure :production do
   require 'newrelic_rpm'

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