class Action < ActiveRecord::Base

  validates :name, :started_at, presence: true
  belongs_to :error

  default_scope -> { order(started_at: :desc) }

  serialize :params, Houston::ParamsSerializer.new



  def self.started_before(time)
    where arel_table[:started_at].lteq time
  end

  def self.record(action_name, params, trigger)
    action = create!(name: action_name, started_at: Time.now, trigger: trigger, params: params)
    begin
      exception = nil

      Houston.reconnect do
        yield
      end

    rescue SocketError,
           Errno::ECONNREFUSED,
           Errno::ETIMEDOUT,
           Faraday::ConnectionFailed,
           Faraday::SSLError,
           Faraday::HTTP::ServerError,
           Faraday::HTTP::Unauthorized,
           Faraday::TimeoutError,
           Rugged::NetworkError,
           Unfuddle::ConnectionError,
           Octokit::BadGateway,
           Octokit::ServerError,
           Octokit::InternalServerError,
           Net::OpenTimeout,
           exceptions_wrapping(PG::ConnectionBad)

      # Note that the action failed, but do not report _these_ exceptions
      exception = $!

    rescue Exception # rescues StandardError by default; but we want to rescue and report all errors

      # Report all other exceptions
      exception = $!
      Houston.report_exception($!, parameters: {
        action_id: action.id,
        action_name: action_name,
        trigger: trigger,
        params: params
      })

    ensure
      begin
        Houston.reconnect do
          action.finish! exception
        end
      rescue Exception # rescues StandardError by default; but we want to rescue and report all errors
        Houston.report_exception($!, parameters: {
          action_id: action.id,
          action_name: action_name,
          trigger: trigger,
          params: params
        })
      end
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
