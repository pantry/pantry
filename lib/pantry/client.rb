module Pantry

  # The pantry Client. The Client runs on any server that needs provisioning,
  # and communicates to the Server through various channels. Clients can
  # be further configured to manage an application, for a given environment,
  # and across any number of roles.
  class Client
    extend Forwardable
    include Celluloid
    finalizer :shutdown

    # See Pantry::ClientInfo
    def_delegators :@info, :identity, :application, :environment, :roles, :filter

    # For testing / debugging purposes, keep hold of the last message this client received
    attr_reader :last_received_message

    def initialize(application: nil, environment: nil, roles: [], identity: nil, network_stack_class: Communication::Client)
      @info      = Pantry::ClientInfo.new(
        application: application,
        environment: environment,
        roles:       roles       || [],
        identity:    identity    || current_hostname
      )

      @commands   = CommandHandler.new(self, Pantry.client_commands)
      @networking = network_stack_class.new_link(self)
    end

    # Start up the Client.
    # This sets up the appropriate communication channels to the
    # server, sends a registration message so the Server knows who
    # just connected, and then waits for information to come.
    def run
      @networking.run
      send_registration_message
      Pantry.logger.info("[#{identity}] Client registered and waiting for commands")
    end

    def shutdown
      Pantry.logger.info("[#{identity}] Client Shutting down")
      @registration_timer.cancel if @registration_timer
    end

    # Callback from Networking when a message is received
    def receive_message(message)
      Pantry.logger.debug("[#{identity}] Received message #{message.inspect}")

      if message_meant_for_us?(message)
        @last_received_message = message
        results = @commands.process(message)

        if message.requires_response?
          Pantry.logger.debug("[#{identity}] Responding with #{results.inspect}")
          send_results_back_to_requester(message, results)
        end
      else
        Pantry.logger.debug("[#{identity}] Message discarded, not for us")
      end
    end

    def send_message(message)
      @networking.send_message(message)
    end

    def send_request(message)
      message.requires_response!

      Pantry.logger.debug("[#{identity}] Sending request #{message.inspect}")

      @networking.send_request(message)
    end

    def receive_file(file_size, file_checksum)
      @networking.receive_file(file_size, file_checksum)
    end

    def send_file(file_path, receiver_uuid)
      @networking.send_file(file_path, receiver_uuid)
    end

    protected

    def current_hostname
      Socket.gethostname
    end

    def send_registration_message
      @networking.send_message(
        Pantry::Commands::RegisterClient.new(self).to_message
      )
      @registration_timer =
        after(Pantry.config.client_heartbeat_interval) { send_registration_message }
    end

    def send_results_back_to_requester(message, results)
      response_message = message.build_response
      response_message << results

      @networking.send_message(response_message)
    end

    # ZeroMQ's Pub/Sub topic matching is too simplistic to catch all the cases we
    # need to handle. Given that if *any* topic matches the incoming message, we get
    # the message even if it wasn't exactly meant for us. For example, if this client
    # subscribes to the following topics:
    #
    #   * pantry
    #   * pantry.test
    #   * pantry.test.app
    #
    # This client will receive messages sent to "pantry.test.web" because "pantry" and
    # "pantry.test" both match (string start_with? check) the message. Thus, we add our
    # own handling to the message check as a protective stop gap.
    def message_meant_for_us?(message)
      filter.matches?(message.to)
    end
  end
end
