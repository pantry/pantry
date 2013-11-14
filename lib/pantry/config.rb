module Pantry

  # Retrieve the current configuration set
  def self.config
    @@config ||= Config.new
  end

  # Global configuration values for running all of Pantry.
  class Config
    ##
    # Communication Configuration
    ##

    # Host name of the Pantry Server
    attr_accessor :server_host

    # Port used for Pub/Sub communication
    attr_accessor :pub_sub_port

    # Port clients use to send information to the Server
    attr_accessor :receive_port

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

    def initialize

      # Default connectivity settings
      @server_host = "127.0.0.1"
      @pub_sub_port = 23001
      @receive_port = 23002

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
      load_networking_configs(configs["networking"])
      load_client_configs(configs["client"])
    end

    protected

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

      if configs["client_heartbeat_interval"]
        @client_heartbeat_interval = configs["client_heartbeat_interval"]
      end
    end

    def load_client_configs(configs)
      return unless configs

      @client_identity    = configs["identity"]
      @client_application = configs["application"]
      @client_environment = configs["environment"]
      @client_roles       = configs["roles"]
    end
  end
end
