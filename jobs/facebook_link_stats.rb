#!/usr/bin/env ruby
require 'net/http'
require 'json'
require 'sinatra/activerecord'
require './models/metric'

# Function to gets FB stats
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

# Save data to db
SCHEDULER.cron '0 0 22 * * *' do
  @metric = Metric.new({
    :metric => 'fblinkstat',
    :created => Time.now,
    :value => get_fb_stats
  })
  
  if @metric.save
    puts 'Save FB stats to DB.'
  end
end

# Send data to dashboard, the total count only
SCHEDULER.every '1m', :first_in => '1s' do
  data = []
  @metrics = Metric.all(:order => 'created ASC').each do |metric|
    puts metric.inspect
    
    if metric.value['items'] == nil
      data << { :x => metric.created.to_i, :y => metric.value[3]['value'] }
    else
      data << { :x => metric.created.to_i, :y => metric.value['items'][3]['value'] }
    end
  end
  
  send_event('fblinkstat', :points => data )
end
