class AddPropsToAuthorizations < ActiveRecord::Migration[5.0]
  def change
    add_column :authorizations, :props, :jsonb, default: {}
  end
end
