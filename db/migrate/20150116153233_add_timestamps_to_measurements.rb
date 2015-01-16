class AddTimestampsToMeasurements < ActiveRecord::Migration
  def change
    add_column :measurements, :created_at, :timestamp
    add_column :measurements, :updated_at, :timestamp
  end
end
