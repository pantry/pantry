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
      @progress_listener = args.delete(:progress_listener) || Pantry::CLIProgressListener.new

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
        @command = command_class.new(*arguments)
        @command.server_or_client  = self
        @command.progress_listener = @progress_listener

        # We don't use send_request here because we don't want to deal with the
        # wait-list future system. This lets command objects handle responses
        # as they come back to the CLI as the command sees fit.
        # If the command isn't meant directly for the Server, the Server will always
        # respond first with the list of clients who will be executing the command
        # and responding with the results. See Pantry::Commands::Echo for an example of how
        # to work with this flow.
        message = @command.prepare_message(filter, arguments)
        message.requires_response!

        send_message(message)

        @command.progress_listener.wait_for_finish
      else
        Pantry.logger.error("[CLI] I don't know the #{command.inspect} command")
      end
    end

    # All messages received by this client are assumed to be responses
    # from previous commands.
    def receive_message(message)
      if @command
        @command.receive_response(message)
      end
    end

  end

end
