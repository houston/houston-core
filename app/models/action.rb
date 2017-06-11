class Action < ActiveRecord::Base

  validates :name, presence: true
  belongs_to :error

  default_scope -> { order(created_at: :desc) }

  serialize :params, Houston::ParamsSerializer.new

  @ignored_exceptions = [
    SocketError,
    Errno::ECONNREFUSED,
    Errno::ETIMEDOUT,
    Faraday::ConnectionFailed,
    Faraday::SSLError,
    Faraday::HTTP::ServerError,
    Faraday::HTTP::Unauthorized,
    Faraday::HTTP::TooManyRequests,
    Faraday::TimeoutError,
    Net::OpenTimeout,
    exceptions_wrapping(PG::ConnectionBad),
    exceptions_wrapping(PG::LockNotAvailable)
  ]



  class << self
    attr_accessor :ignored_exceptions

    def started_before(time)
      where arel_table[:started_at].lteq time
    end

    def running
      where.not(started_at: nil).where(finished_at: nil)
    end

    def unqueued
      where(started_at: nil)
    end

    def run!(action_name, params, trigger)
      action = create!(name: action_name, trigger: trigger, params: params)
      action.run!
    end
  end



  def run!
    exception = nil

    Houston.reconnect do
      touch :started_at
      Houston.actions.fetch(name).execute(params)
    end

  rescue *::Action.ignored_exceptions

    # Note that the action failed, but do not report _these_ exceptions
    exception = $!

  rescue Exception # rescues StandardError by default; but we want to rescue and report all errors

    # Report all other exceptions
    exception = $!
    Houston.report_exception($!, parameters: {
      action_id: id,
      action_name: name,
      trigger: trigger,
      params: params
    })

  ensure
    begin
      Houston.reconnect do
        finish! exception
      end
    rescue Exception # rescues StandardError by default; but we want to rescue and report all errors
      Houston.report_exception($!, parameters: {
        action_id: id,
        action_name: name,
        trigger: trigger,
        params: params
      })
    end
  end

  def retry!
    update_attributes! started_at: Time.now, finished_at: nil, succeeded: nil, exception: nil
    Houston.async do
      run!
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

  def started?
    started_at.present?
  end

  def finished?
    finished_at.present?
  end

  def in_progress?
    started_at.present? && finished_at.nil?
  end

end
