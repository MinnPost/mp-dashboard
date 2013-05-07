#!/usr/bin/env ruby
require 'net/http'
require 'json'
require 'sinatra/activerecord'
require './models/metric_history'

# Function to gets stats
def get_fb_stats
  fbstat = []
  sharedlink = URI::encode('minnpost.com')
 
  http = Net::HTTP.new('graph.facebook.com')
  response = http.request(Net::HTTP::Get.new("/fql?q=SELECT%20share_count,%20like_count,%20comment_count,%20total_count%20FROM%20link_stat%20WHERE%20url=%22#{sharedlink}%22"))
  fbcounts = JSON.parse(response.body)['data']
 
  fbcounts[0].each do |stat|
    fbstat << {:label=>stat[0], :value=>stat[1]}
  end
  
  { items: fbstat }
end

# Send data to dashboard
SCHEDULER.every '2m', :first_in => '1s' do
  send_event('fblinkstat', get_fb_stats)
 
end

# Save data to db
SCHEDULER.every '2m' do
  @MH = MetricHistory.new({
    metric: 'fblinkstat',
    created: Time.now,
    value: get_fb_stats
  })
  if @model.save
    puts 'Save FB stats.'
  end
end