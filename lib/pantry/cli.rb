module Pantry

  # Pantry's Command Line Interface.
  class CLI < Client

    # All commands the CLI knows how to handle.
    # Key is the CLI command, and value is the Command Class that will handle the request,
    # or a Proc/Lambda that knows how to build the command object, if the default doesn't
    # work (e.g ListClients).
    COMMAND_MAP = {
      "echo"      => Pantry::Commands::Echo,
      "status"    => Pantry::Commands::ListClients,
    }

    def initialize(**args)
      args[:identity] ||= ENV["USER"]
      super(**args)
    end

    # Process a command from the command line.
    # Figures out which command handler class to invoke, builds a message from
    # that command class and sends it down the pipe.
    #
    # Returns a CLI::Response object that will eventually have the responses
    # from the Server and/or Clients.
    def request(filter, command, *arguments)
      if command_class = COMMAND_MAP[command]
        command = command_class.new(*arguments)

        @responder = command.handle_response(
          send_request(
            command.prepare_message(filter, arguments)
          )
        )
      else
        Pantry.logger.error("[CLI] I don't know the #{command.inspect} command")
      end
    end

    # All messages received by this client are assumed to be responses
    # from previous commands.
    def receive_message(message)
      if @responder && @responder.respond_to?(:receive_message)
        @responder.receive_message(message)
      end
    end

  end

end
