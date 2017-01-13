class CreateTeams < ActiveRecord::Migration
  def up
    create_table :teams do |t|
      t.string :name
      t.jsonb :props, default: {}
    end

    # Each project belongs to only one team
    add_column :projects, :team_id, :integer

    # Each user can belong to many teams
    # and can have 0 or several roles on each team
    create_table :teams_users do |t|
      t.references :team, :user
      t.string :roles, array: true

      t.timestamps
      t.index [:team_id, :user_id], unique: true
    end
    # rename_table :roles, :project_roles

    # create_table :roles do |t|
    #   t.references :user
    #   t.references :team
    #   t.string :name, false
    #
    #   t.timestamps
    #   t.index [:user_id, :team_id]
    #   t.index [:user_id, :team_id, :name]
    # end
  end

  def down
    drop_table :teams
    # drop_table :roles
    drop_table :teams_users

    remove_column :projects, :team_id

    # rename_table :project_roles, :roles
  end
end
