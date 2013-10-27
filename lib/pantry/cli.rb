module Pantry

  # Pantry's Command Line Interface.
  class CLI < Client

    # All commands the CLI knows how to handle.
    # Key is the CLI command, and value is the Command Class that will handle the request
    COMMAND_MAP = {
      "status" => Pantry::Commands::ListClients
    }

    def shutdown
      @client.shutdown
    end

    # Process a command from the command line.
    # Figures out which command handler class to invoke, builds a message from
    # that command class and sends it down the pipe.
    def request(command)
      if handler = COMMAND_MAP[command]
        message = handler.new.to_message
        message.filter = @client_filter

        send_request(message)
      else
        # TODO Error don't know how to handle command
      end
    end

    # All messages received by this client are assumed to be responses
    # from previous commands.
    def receive_message(message)
      # Do nothing right now
    end

  end

end
