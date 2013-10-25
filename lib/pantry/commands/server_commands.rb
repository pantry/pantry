require 'pantry/commands/command_handler'

module Pantry
  module Commands

    # Server-specific command handler.
    # This class hooks up all commands the server knows how to run.
    class ServerCommands < CommandHandler

      def initialize(server)
        super
      end

    end

  end
end
