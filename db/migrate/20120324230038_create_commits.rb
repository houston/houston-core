class CreateCommits < ActiveRecord::Migration
  def change
    create_table :commits do |t|
      t.integer :release_id
      t.string :sha
      t.text :message
      t.string :committer
      t.date :date

      t.timestamps
    end
  end
end
