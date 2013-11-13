module Pantry

  # Retrieve the current configuration set
  def self.config
    @@config ||= Config.new
  end

  # Global configuration values for running all of Pantry.
  class Config
    # Host name of the Pantry Server
    attr_accessor :server_host

    # Port used for Pub/Sub communication
    attr_accessor :pub_sub_port

    # Port clients use to send information to the Server
    attr_accessor :receive_port

    # How often, in seconds, the client pings the Server
    attr_accessor :client_heartbeat_interval

    def initialize

      # Default connectivity settings
      @server_host = "127.0.0.1"
      @pub_sub_port = 23001
      @receive_port = 23002

      # Default client heartbeat to every 5 minutes
      @client_heartbeat_interval = 300

    end

    # Given a YAML config file, read in config values
    def load_file(config_file)
      configs = YAML.load_file(config_file)
      @server_host  = configs["server_host"]
      @pub_sub_port = configs["pub_sub_port"]
      @receive_port = configs["receive_port"]
    end
  end
end
