class Change < ActiveRecord::Base; end
class EmbedChangesInReleases < ActiveRecord::Migration
  def up
    add_column :releases, :release_changes, :text

    Release.reset_column_information

    Release.find_each do |release|
      release.release_changes = Change.where(release_id: release.id).map do |change|
        ReleaseChange.new(release, change.tag_slug, change.description)
      end
      release.save(validate: false)
    end
  end

  def down
    remove_column :releases, :release_changes
  end
end
