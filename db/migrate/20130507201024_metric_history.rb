class MetricHistory < ActiveRecord::Migration
  def up
    create_table :metric_history do |t|
      t.integer "id"
      t.string "metric"
      t.datetime "created", :null => false
      t.text "value"
    end
  end

  def down
    drop_table :metric_history
  end
end
