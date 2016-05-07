class Error < ActiveRecord::Base

  validates :sha, :message, :backtrace, presence: true

  def self.find_or_create_for_exception(exception)
    message = exception.message
    backtrace = exception.backtrace.join("\n")
    sha = Digest::SHA1.hexdigest([message, backtrace].join)
    create_with(message: message, backtrace: backtrace).find_or_create_by(sha: sha)
  rescue ActiveRecord::RecordNotUnique
    find_by(sha: sha)
  end

end
