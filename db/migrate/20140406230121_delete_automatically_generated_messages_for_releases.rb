class DeleteAutomaticallyGeneratedMessagesForReleases < ActiveRecord::Migration
  def up
    Release.with_message.find_each do |release|
      new_message = release.message.strip
      new_message = "" if new_message =~ /^Hey everyone!\s+\d+ changes? (has|have) been deployed to \w+\.?$/
      release.update_column :message, new_message unless release.message == new_message
    end
  end
  
  def down
  end
end
