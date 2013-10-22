module Pantry
  module Commands

    # Manages and processes commands as requested from the Client or the Server.
    # Given a mapping of available commands, maps the incoming message to the appropriate
    # command handler and returns the response. Returns nil if no command found.
    class CommandHandler
      def initialize
        @handlers = {}
      end

      def add_handler(command_type, &block)
        @handlers[command_type.to_s] = block
      end

      def process(message)
        if handler = @handlers[message.type]
          handler.call(message)
        else
          # Warn log: no command handler found for message type
        end
      end
    end

  end
end
