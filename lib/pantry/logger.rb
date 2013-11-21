module Pantry

  def self.logger
    @@logger ||= Pantry::Logger.new
  end

  # Wrapper around the Celluloid's logging system. Depending on the passed in
  # config, will send to STDOUT, Syslog, or a given file.
  # See Celluloid::Logger for API (should be the same as Ruby's Logger API)
  class Logger

    def initialize(config = Pantry.config)
      logger =
        if config.log_to.nil? || config.log_to == "stdout"
          ::Logger.new(STDOUT)
        elsif config.log_to == "syslog"
          ::Syslog::Logger.new("pantry")
        else
          ::Logger.new(config.log_to)
        end

      Celluloid.logger = logger
    end

    # Turn off all logging entirely
    def disable!
      Celluloid.logger = nil
    end

    # Forward all methods on to the internal Celluloid Logger.
    def method_missing(*args)
      Celluloid.logger.send(*args) if Celluloid.logger
    end

  end

end
