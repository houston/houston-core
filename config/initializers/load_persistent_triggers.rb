Rails.configuration.after_initialize do
  if ActiveRecord::Base.connection.data_source_exists? "persistent_triggers"
    PersistentTrigger.load_all
  else
    Rails.logger.info "\e[94mSkipping PersistentTrigger.load_all since the table doesn't exist\e[0m"
  end
end
