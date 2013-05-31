#!/usr/bin/env ruby
require 'net/http'
require 'json'
require 'date'
require 'gibbon'
require 'sinatra/activerecord'
require './models/metric'

##
# This file holds the jobs that interact with MailChimp
#
# Uses Gibbon, so make the following environmanet variable is set.
# MAILCHIMP_API_KEY
#
# https://github.com/amro/gibbon
##

mc = Gibbon.new
mc_list_minnpost_newsletter = '3631302e9c'
mc_list_donors = 'fe1c25e4f0'

# List numbers by month
SCHEDULER.every '1d', :first_in => '3s' do
  data = []
  
  # Email Newsletter
  list_growth_by_month = mc.listGrowthHistory({ :id => mc_list_minnpost_newsletter })
  list_growth_by_month.each do |g|
    data << { :x => DateTime.strptime(g['month'], '%Y-%m').to_i , 
      :y => (g['existing'].to_i + g['imports'].to_i + g['optins'].to_i) }
  end
  
  send_event('mailchimp_newsletter_list_by_month', :points => data )
  
  # Donor list
  data = []
  list_growth_by_month = mc.listGrowthHistory({ :id => mc_list_donors })
  list_growth_by_month.each do |g|
    data << { :x => DateTime.strptime(g['month'], '%Y-%m').to_i , 
      :y => (g['existing'].to_i + g['imports'].to_i + g['optins'].to_i) }
  end
  
  send_event('mailchimp_donors_list_by_month', :points => data )
end