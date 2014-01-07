module Pantry

  # Retrieve the current configuration set
  def self.config
    @@config ||= Config.new
  end

  # Global configuration values for running all of Pantry.
  class Config
    ##
    # Global Configuration
    ##

    # Where does Pantry log to?
    # Can be "stdout", "syslog", or a file system path
    # Defaults to STDOUT
    # When using syslog, program name will be "pantry"
    attr_accessor :log_to

    # After what level are logs dropped and ignored?
    # Can be any of: "fatal", "error", "warn", "info", "debug"
    # Each level will include the logs of all levels above it.
    # Defaults to "info"
    attr_accessor :log_level

    # If logging to Syslog, set the program-name Pantry will
    # use when sending logs to syslog.
    # Defaults to "pantry"
    attr_accessor :syslog_program_name

    # Location on the file system Pantry will store any persistent data
    # Default: /var/lib/pantry
    attr_accessor :data_dir

    ##
    # Communication Configuration
    ##

    # Host name of the Pantry Server
    attr_accessor :server_host

    # Port used for Pub/Sub communication
    attr_accessor :pub_sub_port

    # Port clients use to send information to the Server
    attr_accessor :receive_port

    # Port through which files are sent and received
    attr_accessor :file_service_port

    # How often, in seconds, the client pings the Server
    attr_accessor :client_heartbeat_interval

    ##
    # Client Identification
    ##

    # Unique identification of this Client
    attr_accessor :client_identity

    # Application this Client serves
    attr_accessor :client_application

    # Environment of the Application this Client runs
    attr_accessor :client_environment

    # Roles this Client serves
    attr_accessor :client_roles

    ##
    # Testing configuration helpers
    ##

    # Time in seconds the CLI will wait for a response from the server
    # By default this is nil, meaning unlimited timeout. Used mainly in tests.
    attr_accessor :response_timeout

    def initialize

      # Logging defaults
      @log_level = "info"
      @data_dir  = "/var/lib/pantry"
      @syslog_program_name = "pantry"

      # Default connectivity settings
      @server_host       = "127.0.0.1"
      @pub_sub_port      = 23001
      @receive_port      = 23002
      @file_service_port = 23003

      # Default client heartbeat to every 5 minutes
      @client_heartbeat_interval = 300

      # Default Client identificiation values
      @client_identity    = nil
      @client_application = nil
      @client_environment = nil
      @client_roles       = []

    end

    # Given a YAML config file, read in config values
    def load_file(config_file)
      configs = YAML.load_file(config_file)
      load_global_configs(configs)
      load_networking_configs(configs["networking"])
      load_client_configs(configs["client"])
      refresh
    end

    def refresh
      apply_configuration
    end

    protected

    def load_global_configs(configs)
      @log_to = configs["log_to"]

      if configs["log_level"]
        @log_level = configs["log_level"]
      end

      if configs["syslog_program_name"]
        @syslog_program_name = configs["syslog_program_name"]
      end

      if configs["data_dir"]
        @data_dir = configs["data_dir"]
      end
    end

    def load_networking_configs(configs)
      return unless configs

      if configs["server_host"]
        @server_host  = configs["server_host"]
      end

      if configs["pub_sub_port"]
        @pub_sub_port = configs["pub_sub_port"]
      end

      if configs["receive_port"]
        @receive_port = configs["receive_port"]
      end

      if configs["file_service_port"]
        @file_service_port = configs["file_service_port"]
      end
    end

    def load_client_configs(configs)
      return unless configs

      @client_identity    = configs["identity"]
      @client_application = configs["application"]
      @client_environment = configs["environment"]
      @client_roles       = configs["roles"]

      if configs["heartbeat_interval"]
        @client_heartbeat_interval = configs["heartbeat_interval"]
      end
    end

    def apply_configuration
      # Reset our logger knowledge so the next call picks up the
      # new configs
      Pantry.logger = nil
    end
  end
end
