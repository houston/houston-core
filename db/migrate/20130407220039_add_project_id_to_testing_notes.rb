class AddProjectIdToTestingNotes < ActiveRecord::Migration
  def up
    add_column :testing_notes, :project_id, :integer

    TestingNote.reset_column_information
    TestingNote.find_each do |testing_note|
      ticket = testing_note.ticket

      if ticket.nil?
        testing_note.delete
        Rails.logger.warn "Deleting testing_note ##{testing_note.id} (#{testing_note.attributes.inspect})"
        next
      end

      testing_note.update_column(:project_id, ticket.project_id)
    end

    change_column_null :testing_notes, :project_id, false

    add_index :testing_notes, [:project_id]
  end

  def down
    remove_column :testing_notes, :project_id
  end
end
