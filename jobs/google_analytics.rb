#!/usr/bin/env ruby
require 'net/http'
require 'json'
require 'oauth2'
require 'legato'
require 'sinatra/activerecord'
require './models/metric'

##
# This holds the tasks around the various Google Analyics
# metrics that are collected.
#
# Overall, Google Analytics API provides historical
# data so that we don't necessarily need to save
# it to the database.
#
# https://developers.google.com/analytics/devguides/reporting/core/v3/
# https://developers.google.com/analytics/devguides/reporting/core/v3/limits-quotas
##

# MinnPost.com propery ID
property_id = 'UA-3385191-1'

# Class for geting page-views per visit
class Pagesviews
  extend Legato::Model

  metrics :pageviewsPerVisit
end

# Connect
def ga_oauth_connect
  client = OAuth2::Client.new(ENV['LEGATO_OAUTH_CLIENT_ID'], ENV['LEGATO_OAUTH_SECRET_KEY'], {
    :authorize_url => 'https://accounts.google.com/o/oauth2/auth',
    :token_url => 'https://accounts.google.com/o/oauth2/token'
  })
  client.auth_code.authorize_url({
    :scope => 'https://www.googleapis.com/auth/analytics.readonly',
    :redirect_uri => 'http://localhost',
    :access_type => 'offline'
  })
  access_token = client.auth_code.get_token(ENV['LEGATO_OAUTH_AUTH_CODE'], :redirect_uri => 'http://localhost')
  response_json = access_token.get('https://www.googleapis.com/analytics/v3/management/accounts').body

  JSON.parse(response_json)
end

# Send page views per visit to dashboard
SCHEDULER.every '30s', :first_in => '1s' do
  data = []
  
  token = ga_oauth_connect()
  
  puts token.inspect
  
  send_event('ga_pages_visit', :points => data )
end
