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

    # List of commands that are meant for the server. Any others are sent
    # through to clients. Will most likely build up a similar Command object structure
    # for CLI commands that handle this kind of logic and clean up the COMMAND_MAP above.
    SERVER_COMMANDS = %w(status)

    # Process a command from the command line.
    # Figures out which command handler class to invoke, builds a message from
    # that command class and sends it down the pipe.
    #
    # Returns a CLI::Response object that will eventually have the responses
    # from the Server and/or Clients.
    def request(filter, command, *arguments)
      if handler = COMMAND_MAP[command]
        message = build_message_from(handler, filter, command, arguments)
        @response = response_class_for(command).new(send_request(message))
      else
        # TODO Error don't know how to handle command
        # raise UnknownCommandError.new(command, arguments)
      end
    end

    # All messages received by this client are assumed to be responses
    # from previous commands.
    def receive_message(message)
      if @response
        @response.receive_message(message)
      end
    end

    protected

    def build_message_from(handler, filter, command, arguments)
      command_obj =
        if handler.respond_to?(:call)
          handler.call(filter, command, arguments)
        else
          handler.new(*arguments)
        end

      message = command_obj.to_message
      message.to = filter.stream unless SERVER_COMMANDS.include?(command)
      message
    end

    def response_class_for(command)
      if SERVER_COMMANDS.include?(command)
        SingleResponse
      else
        MultiResponse
      end
    end

    SERVER_RESPONSE_TIMEOUT = 5 # seconds
    CLIENT_RESPONSE_TIMEOUT = 5 # seconds

    class SingleResponse
      def initialize(server_future)
        @server_future = server_future
      end

      def message
        @server_future.value(SERVER_RESPONSE_TIMEOUT)
      end

      def receive_message(message)
        #no-op
      end
    end

    class MultiResponse
      def initialize(server_future)
        @server_future = server_future
        @messages = []

        # TODO Change this to a Condition on next release of Celluloid
        @wait_on_messages = Celluloid::Future.new
      end

      def messages
        ensure_server_response
        ensure_all_messages_received
        @messages
      end

      FutureResultWrapper = Struct.new(:value)
      def receive_message(message)
        @messages << message

        if @server_response && @messages.length >= @server_response.body.length
          @wait_on_messages.signal(FutureResultWrapper.new(nil))
        end
      end

      protected

      def ensure_server_response
        @server_response = @server_future.value(SERVER_RESPONSE_TIMEOUT)
      end

      def ensure_all_messages_received
        begin
          @wait_on_messages.value(CLIENT_RESPONSE_TIMEOUT)
        rescue Celluloid::TimeoutError
          puts "Did not get signal, returning known list of messages"
        end
      end
    end

  end

end
