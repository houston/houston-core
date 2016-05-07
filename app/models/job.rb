class Job < ActiveRecord::Base

  validates :name, :started_at, presence: true
  belongs_to :error

  default_scope -> { order(started_at: :desc) }



  def self.record(job_name)
    job = Job.create!(name: job_name, started_at: Time.now)
    exception = nil

    yield

  rescue SocketError,
         Errno::ECONNREFUSED,
         Errno::ETIMEDOUT,
         Faraday::ConnectionFailed,
         Faraday::HTTP::ServerError,
         Rugged::NetworkError,
         Unfuddle::ConnectionError,
         Octokit::BadGateway,
         exceptions_wrapping(PG::ConnectionBad)

    # Note that the job failed, but do not report _these_ exceptions
    exception = $!

  rescue Exception # rescues StandardError by default; but we want to rescue and report all errors

    # Report all other exceptions
    exception = $!
    Houston.report_exception($!, parameters: {job_id: job.id, job_name: job_name})

  ensure
    begin
      job.finish! exception
    rescue Exception # rescues StandardError by default; but we want to rescue and report all errors
      Houston.report_exception($!, parameters: {job_id: job.id, job_name: job_name})
    end
  end



  def exception=(exception)
    self.error = Error.find_or_create_for_exception(exception) if exception
  end

  def finish!(exception)
    update_attributes! finished_at: Time.now, succeeded: exception.nil?, exception: exception
  end

  def duration
    return nil unless finished?
    finished_at - started_at
  end

  def finished?
    finished_at.present?
  end

  def in_progress?
    finished_at.nil?
  end

end
