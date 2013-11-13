module Pantry

  # The pantry Client. The Client runs on any server that needs provisioning,
  # and communicates to the Server through various channels. Clients can
  # be further configured to manage an application, for a given environment,
  # and across any number of roles.
  class Client
    include Celluloid

    attr_reader :application

    attr_reader :environment

    attr_reader :roles

    # The above gets packaged into a ClientFilter for use elsewhere
    attr_reader :filter

    # This client's current identity. By default a client's identity is it's `hostname`,
    # but a specific one can be given. These identities should be unique across the set
    # of clients connecting to a single Pantry Server, behavior of multiple clients with
    # the same identity is currently undefined.
    attr_reader :identity

    # For testing / debugging purposes, keep hold of the last message this client received
    attr_reader :last_received_message

    def initialize(application: nil, environment: nil, roles: [], identity: nil, network_stack_class: Communication::Client)
      @application = application
      @environment = environment
      @roles       = roles
      @identity    = identity || current_hostname

      @filter      = Pantry::Communication::ClientFilter.new(
        application: @application,
        environment: @environment,
        roles:       @roles,
        identity:    @identity
      )

      @commands   = CommandHandler.new(self, Pantry.client_commands)
      @networking = network_stack_class.new(self)
    end

    # Start up the Client.
    # This sets up the appropriate communication channels to the
    # server, sends a registration message so the Server knows who
    # just connected, and then waits for information to come.
    def run
      @networking.run
      send_registration_message
      Pantry.logger.info("[#{@identity}] Client registered and waiting for commands")
    end

    # Close down all communication channels and clean up resources
    def shutdown
      Pantry.logger.info("[#{@identity}] Client Shutting down")
      @networking.shutdown
    end

    # Callback from SubscribeSocket when a message is received
    def receive_message(message)
      Pantry.logger.debug("[#{@identity}] Received message #{message.inspect}")

      @last_received_message = message
      results = @commands.process(message)

      if message.requires_response?
        Pantry.logger.debug("[#{@identity}] Responding with #{results.inspect}")
        send_results_back_to_requester(message, results)
      end
    end

    # Send a message to the Server
    def send_request(message)
      message.requires_response!

      Pantry.logger.debug("[#{@identity}] Sending request #{message.inspect}")

      @networking.send_request(message)
    end

    protected

    def current_hostname
      Socket.gethostname
    end

    def send_registration_message
      @networking.send_message(
        Pantry::Commands::RegisterClient.new(self).to_message
      )
      after(Pantry.config.client_heartbeat_interval) { send_registration_message }
    end

    def send_results_back_to_requester(message, results)
      response_message = message.build_response
      response_message << results

      @networking.send_message(response_message)
    end

  end
end
