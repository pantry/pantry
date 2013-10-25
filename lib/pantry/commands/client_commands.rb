require 'pantry/commands/command_handler'

require 'pantry/commands/execute_shell'

module Pantry
  module Commands

    # Client-specific command handler.
    # This class hooks up all commands the client knows how to run.
    class ClientCommands < CommandHandler

      def initialize(client)
        super
        install_handlers
      end

      def install_handlers
        add_command(ExecuteShell)
      end

    end

  end
end
