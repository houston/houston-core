module Houston

  def self.deliver!(message)
    Houston.try({max_tries: 3},
                Errno::ECONNRESET,
                Errno::EPIPE,
                Errno::ETIMEDOUT,
                Net::OpenTimeout,
                Net::ReadTimeout,
                Net::SMTPServerBusy,
                EOFError) do
        message.deliver!
    end
  end

end
