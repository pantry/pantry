module Pantry

  # Pantry's Command Line Interface.
  class CLI < Client

    # All commands the CLI knows how to handle.
    # Key is the CLI command, and value is the Command Class that will handle the request,
    # or a Proc/Lambda that knows how to build the command object, if the default doesn't
    # work (e.g ListClients).
    COMMAND_MAP = {
      "echo"   => Pantry::Commands::Echo,
      "status" => lambda {|filter, command, arguments|
        Pantry::Commands::ListClients.new(filter)
      }
    }

    # List of commands that are meant for the server. Any others are sent
    # through to clients. Will most likely build up a similar Command object structure
    # for CLI commands that handle this kind of logic and clean up the COMMAND_MAP above.
    SERVER_COMMANDS = %w(status)

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
      if handler = COMMAND_MAP[command]
        message = build_message_from(handler, filter, command, arguments)
        @response = response_class_for(command).new(send_request(message))
      else
        Pantry.logger.error("[CLI] I don't know the #{command.inspect} command")
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
        begin
          @server_future.value(SERVER_RESPONSE_TIMEOUT)
        rescue Celluloid::TimeoutError => e
          Pantry.logger.error("[CLI] Did not recieve any response from the server")
          nil
        end
      end

      def messages
        @messages ||= [message].compact
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
        ensure_server_response
      end

      def messages
        ensure_all_messages_received
        @messages
      end

      FutureResultWrapper = Struct.new(:value)
      def receive_message(message)
        Pantry.logger.debug("[CLI] Received message #{message.inspect}")
        @messages << message

        if @server_response && @messages.length >= @server_response.body.length
          Pantry.logger.debug("[CLI] Received all expected messages")
          @wait_on_messages.signal(FutureResultWrapper.new("success"))
        end
      end

      protected

      def ensure_server_response
        begin
          @server_response = @server_future.value(SERVER_RESPONSE_TIMEOUT)
        rescue Celluloid::TimeoutError
          Pantry.logger.error("[CLI] Did not receive response from Server in time.")
        end
      end

      def ensure_all_messages_received
        begin
          @wait_on_messages.value(CLIENT_RESPONSE_TIMEOUT)
        rescue Celluloid::TimeoutError
          Pantry.logger.error("[CLI] Did not receive all expected messages.")
        end
      end
    end

  end

end
