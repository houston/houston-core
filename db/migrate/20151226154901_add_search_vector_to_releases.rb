class AddSearchVectorToReleases < ActiveRecord::Migration
  def change
    add_column :releases, :search_vector, :tsvector
    add_index :releases, :search_vector, using: :gin
  end
end
