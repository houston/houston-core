class CreateFollows < ActiveRecord::Migration[5.0]
  class Role < ActiveRecord::Base
    belongs_to :project
    belongs_to :user
  end

  def up
    create_table :follows do |t|
      t.belongs_to :user, foreign_key: { on_delete: :cascade }
      t.belongs_to :project, foreign_key: { on_delete: :cascade }
    end

    Follow.import(Role.joins(:project, :user).distinct.pluck(:user_id, :project_id).map { |user_id, project_id|
      { user_id: user_id, project_id: project_id } })
  end

  def down
    drop_table :follows
  end
end
