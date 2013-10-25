require 'pantry/client'
require 'pantry/commands/list_clients'

module Pantry

  # Pantry's Command Line Interface.
  # Is a Pantry::Client for all intents and purposes, builds and handles a mapping
  # between CLI input and commands to request.
  class CLI

    # All commands the CLI knows how to handle.
    # Key is the CLI command, and value is the Command Class that will handle the request
    COMMAND_MAP = {
      "status" => Commands::ListClients
    }

    def initialize
      # TODO Figure out this CLI's identity and pass it into the Client
      # Also, hook an at_exit @client.shutdown?
      @client = Pantry::Client.new
      @client.run
    end

    # Process a command from the command line.
    # Figures out which command handler class to invoke, builds a message from
    # that command class and sends it down the pipe.
    def request(command)
      if handler = COMMAND_MAP[command]
        @client.send_request(handler.new.to_message)
      else
        # TODO Error don't know how to handle command
      end
    end

  end

end
