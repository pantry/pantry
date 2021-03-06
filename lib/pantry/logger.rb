module Pantry

  # Access Pantry's logger.
  def self.logger
    @@logger ||= Pantry::Logger.new
  end

  def self.logger=(logger)
    @@logger = logger
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
          ::Syslog::Logger.new(config.syslog_program_name)
        else
          ::Logger.new(config.log_to)
        end

      logger.level = log_level(config.log_level)
      Celluloid.logger = logger
    end

    # Turn off all logging entirely
    def disable!
      Celluloid.logger = NullLogger.new
    end

    # Forward all methods on to the internal Celluloid Logger.
    def method_missing(*args)
      Celluloid.logger.send(*args) if Celluloid.logger
    end

    protected

    def log_level(log_level_string)
      case log_level_string.to_s
      when "debug"
        ::Logger::DEBUG
      when "info"
        ::Logger::INFO
      when "warn"
        ::Logger::WARN
      when "error"
        ::Logger::ERROR
      when "fatal"
        ::Logger::FATAL
      else
        raise "Unknown log level given: #{log_level_string}"
      end
    end

  end

  # Because Celluloid tries to log things on shut-down that throw
  # tons of exceptions if the logger is nil
  class NullLogger
    def debug(*args)
    end

    def info(*args)
    end

    def warn(*args)
    end

    def error(*args)
    end
  end

end
