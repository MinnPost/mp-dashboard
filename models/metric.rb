class Metric < ActiveRecord::Base
  
  serialize :value, JSON
end