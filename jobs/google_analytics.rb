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

# Global for Google API client, probably not the best.
$gapi_client

# GA profile IDs
ga_profile_id_minnpost_com = '6603264'

# Connect
def ga_connect
  if $gapi_client == nil
    puts 'Making Google Analytics client connector.'
    
    $gapi_client = Google::APIClient.new(
      :application_name => 'MP Dashboard',
      :application_version => '0.0.1')
      
    key = OpenSSL::PKey::RSA.new(ENV['DASHING_GAPI_PRIVATE_KEY'], 'notasecret')
    $gapi_client.authorization = Signet::OAuth2::Client.new(
      :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
      :audience => 'https://accounts.google.com/o/oauth2/token',
      :scope => 'https://www.googleapis.com/auth/analytics.readonly',
      :issuer => ENV['DASHING_GAPI_ISSUER'],
      :signing_key => key)
      
    $gapi_client.authorization.fetch_access_token!
  end
end

# Send page views per visit to dashboard
SCHEDULER.every '1d', :first_in => '1s' do
  data = []
  ga_connect()
  analytics = $gapi_client.discovered_api('analytics', 'v3')
  
  # Get last year per month
  start_date = DateTime.now.prev_year.strftime('%Y-%m-%d')
  end_date = DateTime.now.strftime('%Y-%m-01')
  per_month = $gapi_client.execute(:api_method => analytics.data.ga.get, :parameters => { 
    'ids' => 'ga:' + ga_profile_id_minnpost_com,
    'start-date' => start_date,
    'end-date' => end_date,
    'dimensions' => 'ga:year,ga:month',
    'metrics' => 'ga:pageviewsPerVisit',
    'filters' => 'ga:region==Minnesota'
  })
  
  per_month.data.rows.each do |r|
    data << { :x => DateTime.strptime(r[0] + r[1], '%Y%m').to_i , :y => r[2].to_f.round(3) }
  end
  
  send_event('google_analytics_page_views_per_visit_mn', :points => data )
end

# Average visits per month
SCHEDULER.every '1d', :first_in => '5s' do
  data = []
  ga_connect()
  analytics = $gapi_client.discovered_api('analytics', 'v3')
  
  # Get last year per month
  start_date = DateTime.now.prev_year.strftime('%Y-%m-%d')
  end_date = DateTime.now.strftime('%Y-%m-01')
  per_month = $gapi_client.execute(:api_method => analytics.data.ga.get, :parameters => { 
    'ids' => 'ga:' + ga_profile_id_minnpost_com,
    'start-date' => start_date,
    'end-date' => end_date,
    'dimensions' => 'ga:year,ga:month',
    'metrics' => 'ga:visitors,ga:visits',
    'filters' => 'ga:region==Minnesota'
  })
  
  # ga:year 	ga:month 	ga:visitors 	ga:visits 
  per_month.data.rows.each do |r|
    data << { :x => DateTime.strptime(r[0] + r[1], '%Y%m').to_i , :y => (r[3].to_f / r[2].to_f).round(3) }
  end
  
  send_event('google_analytics_visits_month_mn', :points => data )
end

# Average visits per week
SCHEDULER.every '1d', :first_in => '5s' do
  data = []
  ga_connect()
  analytics = $gapi_client.discovered_api('analytics', 'v3')
  
  # Get last year per week
  start_date = DateTime.now.prev_year.strftime('%Y-%m-%d')
  end_date = DateTime.now.strftime('%Y-%m-01')
  per_week = $gapi_client.execute(:api_method => analytics.data.ga.get, :parameters => { 
    'ids' => 'ga:' + ga_profile_id_minnpost_com,
    'start-date' => start_date,
    'end-date' => end_date,
    'dimensions' => 'ga:year,ga:week',
    'metrics' => 'ga:visitors,ga:visits',
    'filters' => 'ga:region==Minnesota',
    'max-results' => '1000'
  })
  
  # ga:year 	ga:month 	ga:visitors 	ga:visits 
  per_week.data.rows.each do |r|
    data << { :x => DateTime.strptime(r[0] + r[1], '%Y%W').to_i , :y => (r[3].to_f / r[2].to_f).round(3) }
  end
  
  send_event('google_analytics_visits_week_mn', :points => data )
end