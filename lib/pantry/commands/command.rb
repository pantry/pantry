require 'pantry/communication/message'

module Pantry
  module Commands

    # Base class of all Commands, this offers up some sane defaults for working
    # with Commands and their interactions with Messages.
    # All commands must implement #perform, which should return the values that
    # should be sent back to the requester.
    class Command

      # Save the Message that triggered the creation of this Command
      attr_accessor :message

      # Run whatever this command needs to do.
      # All Command subclasses must implement this method.
      def perform
      end

      # Create a new Command from the given Message
      def self.from_message(message)
        self.new
      end

      # Create a new Message from the information in the current Command
      def to_message
        Pantry::Communication::Message.new(Command.command_type(self.class))
      end

      def self.command_type(command_class)
        command_class.name.split("::").last
      end

      # Set a link back to the Server or Client that's handling
      # this command. This will be set by the CommandHandler before calling
      # #perform.
      def server_or_client=(server_or_client)
        @server_or_client = server_or_client
      end

      # Get the Server handling this command
      def server
        @server_or_client
      end

      # Get the Client handling this command
      def client
        @server_or_client
      end

    end

  end
end
