#!/usr/bin/env ruby
require 'net/http'
require 'json'
require 'sinatra/activerecord'
require './models/metric'

# Function to gets FB links stats
def get_fb_stats
  fbstat = []
  
  sharedlink = URI::encode('minnpost.com')
  http = Net::HTTP.new('graph.facebook.com')
  response = http.request(Net::HTTP::Get.new("/fql?q=SELECT%20share_count," +
    "%20like_count,%20comment_count,%20total_count%20FROM%20link_stat%20" +
    "WHERE%20url=%22#{sharedlink}%22"))
  fbcounts = JSON.parse(response.body)['data']
 
  fbcounts[0].each do |stat|
    fbstat << { :label => stat[0], :value => stat[1] }
  end
  
  fbstat
end

# Save metric: link stats
SCHEDULER.cron '0 15 * * * *' do
  @metric = Metric.new({
    :metric => 'fb_link_stats',
    :created => Time.now,
    :value => get_fb_stats
  })
  
  if @metric.save
    puts 'Save FB stats to DB.'
  end
end

# Send data to dashboard: link stats, total count
SCHEDULER.every '10m', :first_in => '1s' do
  data = []
  
  # Get historical data
  @metrics = Metric.find_all_by_metric('fb_link_stats', :order => 'created ASC').each do |metric|
    data << { :x => metric.created.to_i, :y => metric.value[3]['value'] }
  end
  
  # Get new data
  data << { :x => Time.now.to_i, :y => get_fb_stats()[3][:value] }
  
  send_event('fb_link_stats_total_count', :points => data )
end
