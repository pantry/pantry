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
        add_command(Echo)
        add_command(ExecuteShell)
        add_command(RunChefSolo)
      end

    end

  end
end
