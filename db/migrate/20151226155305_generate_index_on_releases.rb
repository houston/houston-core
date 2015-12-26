class GenerateIndexOnReleases < ActiveRecord::Migration
  def change
    Release.reindex!
  end
end
