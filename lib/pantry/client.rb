require 'pantry/communication/client'
require 'pantry/communication/client_filter'
require 'pantry/commands/client_commands'
require 'pantry/commands/register_client'

require 'socket'

module Pantry

  # The pantry Client. The Client runs on any server that needs provisioning,
  # and communicates to the Server through various channels. Clients can
  # be further configured to manage an application, for a given environment,
  # and across any number of roles.
  class Client

    attr_reader :application

    attr_reader :environment

    attr_reader :roles

    # This client's current identity. By default a client's identity is it's `hostname`,
    # but a specific one can be given. These identities should be unique across the set
    # of clients connecting to a single Pantry Server, behavior of multiple clients with
    # the same identity is currently undefined.
    attr_reader :identity

    def initialize(application: nil, environment: nil, roles: [], identity: nil, network_stack_class: Communication::Client)
      @application = application
      @environment = environment
      @roles       = roles
      @identity    = identity || current_hostname

      @commands   = Commands::ClientCommands.new(self)
      @networking = network_stack_class.new(self)
    end

    # Start up the Client.
    # This sets up the appropriate communication channels to the
    # server, sends a registration message so the Server knows who
    # just connected, and then waits for information to come.
    def run
      @networking.run
      send_registration_message
    end

    # Close down all communication channels and clean up resources
    def shutdown
      @networking.shutdown
    end

    # Map a message event type to a handler Proc.
    # All messages have a type, use this method to register a block to
    # handle any messages that come to this Client of the given type.
    def on(message_type, &block)
      @commands.add_handler(message_type, &block)
    end

    # Callback from SubscribeSocket when a message is received
    def receive_message(message)
      results = @commands.process(message)
      if message.requires_response?
        send_results_back_to_requester(message, results)
      end
    end

    # Send a message to the Server
    def send_request(message)
      message.requires_response!
      message.source = self

      @networking.send_request(message)
    end

    protected

    def current_hostname
      Socket.gethostname
    end

    def send_registration_message
      message = Pantry::Commands::RegisterClient.new(self).to_message
      message.source = self

      @networking.send_message(message)
    end

    def send_results_back_to_requester(message, results)
      response_message = message.build_response
      response_message.source = self
      response_message << results

      @networking.send_message(response_message)
    end

  end
end
