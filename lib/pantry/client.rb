require 'pantry/communication/client'
require 'pantry/communication/message_filter'

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

      @networking = network_stack_class.new(self)

      @message_subscriptions = {}
    end

    # Start up the Client.
    # This sets up the appropriate communication channels to the
    # server and then waits for information to come.
    def run
      @networking.run
    end

    # Map a message event type to a handler Proc.
    # All messages have a type, use this method to register a block to
    # handle any messages that come to this Client of the given type.
    # TODO Move this or something like it to networking? Server needs the same
    # Will actually probably build a Command system and drop this entirely
    def on(message_type, &block)
      @message_subscriptions[message_type.to_s] = block
    end

    # Callback from SubscribeSocket when a message is received
    def receive_message(message)
      if callback = @message_subscriptions[message.type]
        results = callback.call(message)

        if message.requires_response?
          send_results_back_to_requester(message, results)
        end
      end
    end

    # Send a message to the Server
    def send_request(message)
      message.requires_response!
      message.source = self

      @networking.send_request(message)
    end

    # Close down all communication channels and clean up resources
    def shutdown
      @networking.shutdown
    end

    protected

    def current_hostname
      Socket.gethostname
    end

    def send_results_back_to_requester(message, results)
      response_message = message.build_response
      response_message.source = self
      response_message << results

      @networking.send_message(response_message)
    end

  end
end
