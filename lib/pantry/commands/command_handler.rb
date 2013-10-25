module Pantry
  module Commands

    # Manages and processes commands as requested from the Client or the Server.
    # Given a mapping of available commands, maps the incoming message to the appropriate
    # command handler and returns the response. Returns nil if no command found.
    class CommandHandler
      def initialize(server_or_client)
        @handlers = {}
        @server_or_client = server_or_client
      end

      def add_handler(command_type, &block)
        @handlers[command_type.to_s] = block
      end

      # Install a Command class as a message handler for this process.
      # The Message's +type+ for this kind of message is simply the name of the class
      # without any scope information. E.g. ExecuteShell not Pantry::Command::ExecuteShell.
      def add_command(command_class)
        @handlers[Command.command_type(command_class)] = build_command_proc(command_class)
      end

      # Given a message, figure out which handler should be triggered and get things rolling
      def process(message)
        if handler = @handlers[message.type]
          handler.call(message)
        else
          # Warn log: no command handler found for message type
        end
      end

      protected

      def build_command_proc(command_class)
        proc do |message|
          command_obj = command_class.from_message(message)
          command_obj.server_or_client = @server_or_client
          command_obj.message          = message
          command_obj.perform
        end
      end
    end

  end
end
