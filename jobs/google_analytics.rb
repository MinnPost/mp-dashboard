#!/usr/bin/env ruby
require 'net/http'
require 'json'
require 'date'
require 'google/api_client'
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

# GA profile IDs
profile_id_minnpost_com = '6603264'

# Connect
def ga_connect
  client = Google::APIClient.new(
    :application_name => 'MP Dashboard',
    :application_version => '0.0.1')
    
  key = OpenSSL::PKey::RSA.new(ENV['DASHING_GAPI_PRIVATE_KEY'], 'notasecret')
  client.authorization = Signet::OAuth2::Client.new(
    :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
    :audience => 'https://accounts.google.com/o/oauth2/token',
    :scope => 'https://www.googleapis.com/auth/analytics.readonly',
    :issuer => ENV['DASHING_GAPI_ISSUER'],
    :signing_key => key)
    
  client.authorization.fetch_access_token!
  
  client
end

# Send page views per visit to dashboard
SCHEDULER.every '30s', :first_in => '1s' do
  data = []
  
  client = ga_connect()
  analytics = client.discovered_api('analytics', 'v3')
  startDate = DateTime.now.prev_month.strftime("%Y-%m-%d")
  endDate = DateTime.now.strftime("%Y-%m-%d")
  
  visitCount = client.execute(:api_method => analytics.data.ga.get, :parameters => { 
    'ids' => 'ga:' + profile_id_minnpost_com,
    'start-date' => startDate,
    'end-date' => endDate,
    'dimensions' => 'ga:month,ga:week',
    'metrics' => 'ga:pageviewsPerVisit'
  })
  
  puts visitCount.data.column_headers.map { |c|
    c.name  
  }.join("\t")
  
  visitCount.data.rows.each do |r|
    puts r.join("\t"), "\n"
  end
  
  send_event('ga_pages_visit', :points => data )
end
