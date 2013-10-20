require 'pantry/config'
require 'pantry/communication/message'
require 'pantry/communication/subscribe_socket'
require 'pantry/communication/send_socket'

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
    # of clients connecting to a single Pantry Server, but the system will happily
    # send messages to multiple clients with the same identity, however responses are not
    # guarenteed to be consistent.
    attr_reader :identity

    def initialize(application: nil, environment: nil, roles: [], identity: nil)
      @application = application
      @environment = environment
      @roles       = roles
      @identity    = identity || current_hostname

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
        Communication::MessageFilter.new(
          application: @application,
          environment: @environment,
          roles: @roles,
          identity: @identity
        )
      )
      @subscribe_socket.open

      @send_socket = Communication::SendSocket.new(
        Pantry.config.server_host,
        Pantry.config.receive_port
      )
      @send_socket.open
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
      @send_socket.close
    end

    protected

    def current_hostname
      Socket.gethostname
    end

  end
end
