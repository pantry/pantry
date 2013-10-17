require 'pantry/config'
require 'pantry/communication/message'
require 'pantry/communication/subscribe_socket'

module Pantry

  # The pantry Client. The Client runs on any server that needs provisioning,
  # and communicates to the Server through various channels. Clients can
  # be further configured to manage an application, for a given environment,
  # and across any number of roles.
  class Client

    attr_reader :application

    attr_reader :environment

    attr_reader :roles

    def initialize(application: nil, environment: nil, roles: [])
      @application = application
      @environment = environment
      @roles       = roles

      @message_subscriptions = {}
    end

    # Start up the Client.
    # This sets up the appropriate communication channels to the
    # server and then waits for information to come.
    def run
      @subscribe_socket = Communication::SubscribeSocket.new(
        Pantry.config.server_host,
        Pantry.config.pub_sub_port
      )
      @subscribe_socket.add_listener(self)
      @subscribe_socket.filter_on(
        application: @application,
        environment: @environment,
        roles: @roles
      )
      @subscribe_socket.open
    end

    # Map a message event type to a handler Proc.
    # All messages have a type, use this method to register a block to
    # handle any messages that come to this Client of the given type.
    def on(message_type, &block)
      @message_subscriptions[message_type.to_s] = block
    end

    # Callback from SubscribeSocket when a message is received
    def handle_message(message)
      if callback = @message_subscriptions[message.type]
        callback.call(message)
      end
    end

    # Close down all communication channels and clean up resources
    def shutdown
      @subscribe_socket.close
    end

  end
end
