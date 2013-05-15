class CreateMetrics < ActiveRecord::Migration
  def up
    create_table :metrics do |t|
      t.integer "id"
      t.string "metric"
      t.datetime "created", :null => false
      t.text "value"
    end
  end

  def down
    drop_table :metrics
  end
end
