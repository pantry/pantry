module Pantry

  # Pantry's Command Line Interface.
  # Is a Pantry::Client for all intents and purposes, builds and handles a mapping
  # between CLI input and commands to request.
  class CLI

    # All commands the CLI knows how to handle.
    # Key is the CLI command, and value is the Command Class that will handle the request
    COMMAND_MAP = {
      "status" => Pantry::Commands::ListClients
    }

    # Set up a new CLI, optionally passing in a set of filters to limit the set of
    # Clients we're trying to request info from.
    def initialize(client_filter = nil)
      # TODO Figure out this CLI's identity and pass it into the Client
      # Also, hook an at_exit @client.shutdown?
      @client = Pantry::Client.new
      @client.run

      @client_filter = client_filter || Pantry::Communication::ClientFilter.new
    end

    # Process a command from the command line.
    # Figures out which command handler class to invoke, builds a message from
    # that command class and sends it down the pipe.
    def request(command)
      if handler = COMMAND_MAP[command]
        message = handler.new.to_message
        message.filter = @client_filter

        @client.send_request(message)
      else
        # TODO Error don't know how to handle command
      end
    end

  end

end
