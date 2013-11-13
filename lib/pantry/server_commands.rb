module Pantry

  # Server-specific command handler.
  # This class hooks up all commands the server knows how to run.
  class ServerCommands < CommandHandler

    def initialize(server)
      super
      install_handlers
    end

    def install_handlers
      add_command(Commands::Echo)
      add_command(Commands::ListClients)
      add_command(Commands::RegisterClient)
    end

  end

end
