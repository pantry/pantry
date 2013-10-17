require 'pantry/config'
require 'pantry/communication/message'
require 'pantry/communication/subscribe_socket'

module Pantry
  # The pantry Client
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

    def on(message_type, &block)
      @message_subscriptions[message_type.to_s] = block
    end

    # Callback from SubscribeSocket when a message is received
    def handle_message(message)
      if callback = @message_subscriptions[message.type]
        callback.call(message)
      end
    end

    def shutdown
      @subscribe_socket.close
    end

  end
end
