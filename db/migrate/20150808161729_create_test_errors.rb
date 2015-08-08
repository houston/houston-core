class CreateTestErrors < ActiveRecord::Migration
  def change
    create_table :test_errors do |t|
      t.string :sha
      t.text :output

      t.index :sha, unique: true
    end
  end
end
