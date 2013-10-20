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
  end
end
