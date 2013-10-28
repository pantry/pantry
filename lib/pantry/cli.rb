module Pantry

  # Pantry's Command Line Interface.
  class CLI < Client

    # All commands the CLI knows how to handle.
    # Key is the CLI command, and value is the Command Class that will handle the request,
    # or a Proc/Lambda that knows how to build the command object, if the default doesn't
    # work (e.g ListClients).
    COMMAND_MAP = {
      "status"  => lambda {|filter, command, arguments|
        Pantry::Commands::ListClients.new(filter)
      },
      "execute" => Pantry::Commands::ExecuteShell
    }

    def shutdown
      @client.shutdown
    end

    # Process a command from the command line.
    # Figures out which command handler class to invoke, builds a message from
    # that command class and sends it down the pipe.
    def request(filter, command, *arguments)
      if handler = COMMAND_MAP[command]
        message = build_message_from(handler, filter, command, arguments)
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

    protected

    def build_message_from(handler, filter, command, arguments)
      command =
        if handler.respond_to?(:call)
          handler.call(filter, command, arguments)
        else
          handler.new(*arguments)
        end

      command.to_message
    end

  end

end
