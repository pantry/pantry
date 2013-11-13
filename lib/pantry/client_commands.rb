module Pantry

  # Client-specific command handler.
  # This class hooks up all commands the client knows how to run.
  class ClientCommands < CommandHandler

    def initialize(client)
      super
      install_handlers
    end

    def install_handlers
      add_command(Commands::Echo)
      add_command(Commands::ExecuteShell)
      add_command(Commands::RunChefSolo)
    end

  end

end
