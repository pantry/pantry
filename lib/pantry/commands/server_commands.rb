module Pantry
  module Commands

    # Server-specific command handler.
    # This class hooks up all commands the server knows how to run.
    class ServerCommands < CommandHandler

      def initialize(server)
        super
        install_handlers
      end

      def install_handlers
        add_command(RegisterClient)
        add_command(ListClients)
      end

    end

  end
end
