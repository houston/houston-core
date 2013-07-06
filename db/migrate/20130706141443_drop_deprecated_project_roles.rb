class DropDeprecatedProjectRoles < ActiveRecord::Migration
  def up
    Role.where(name: %w{Contributor Tester}).delete_all
  end

  def down
    raise IrreversibleMigration
  end
end
