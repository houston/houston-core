class PreventHstoreFieldsFromBeingNull < ActiveRecord::Migration
  FIELDS = [
    [:milestones, :extended_attributes],
    [:projects,   :extended_attributes],
    [:projects,   :view_options],
    [:projects,   :feature_states],
    [:tickets,    :extended_attributes],
    [:users,      :view_options]
  ]
  
  def up
    FIELDS.each do |(table, column)|
      change_column table, column, :hstore, null: false, default: ''
    end
  end
  
  def down
    FIELDS.each do |(table, column)|
      change_column table, column, :hstore, null: true, default: nil
    end
  end
end
