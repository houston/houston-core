class Error < ActiveRecord::Base
  self.inheritance_column = nil # <-- Error has a column named 'type'

  validates :sha, :message, :backtrace, presence: true

  def self.find_or_create_for_exception(exception)
    message = exception.message
    backtrace = exception.backtrace.join("\n")
    sha = Digest::SHA1.hexdigest([message, backtrace].join)
    error = create_with(
      type: exception.class.name,
      message: message,
      backtrace: backtrace
    ).find_or_create_by(sha: sha)

    # TODO: we'll move this to `create_with` and incorporate it into the SHA;
    # but for now we'll try to collect types for errors
    error.update_column :type, exception.class.name unless error.type
    error
  rescue ActiveRecord::RecordNotUnique
    find_by(sha: sha)
  end

end
