class LegacyRole < ActiveRecord::Base
  self.table_name = "roles"
end

class DropDeprecatedProjectRoles < ActiveRecord::Migration
  def up
    LegacyRole.where(name: %w{Contributor Tester}).delete_all
  end

  def down
    raise IrreversibleMigration
  end
end
