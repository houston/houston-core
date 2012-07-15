class ChangeTestingNotesCommentToText < ActiveRecord::Migration
  def up
    change_column :testing_notes, :comment, :text
  end

  def down
    change_column :testing_notes, :comment, :string
  end
end
