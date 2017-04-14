class DropConsumerTokens < ActiveRecord::Migration[5.0]
  def up
    drop_table :consumer_tokens
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
