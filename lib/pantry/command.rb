module Pantry

  # Commands are where the task-specific functionality is implemented, the
  # core of how Pantry works. All Commands are required to implement the #perform method,
  # which receives the Pantry::Message requesting the Command.
  #
  # All commands must be registered with Pantry before they will be available for execution.
  # Use Pantry.add_client_command or Pantry.add_server_command to register the Command.
  class Command

    class << self
      # Expose this Command to the CLI and configure the options and information
      # that this Command needs from the CLI to function.
      #
      # See OptParsePlus for documentation
      def command(name, &block)
        @command_name   = name
        @command_config = block
      end
      attr_reader :command_name
      attr_reader :command_config
    end

    # Initialize this Command
    # Due to the multiple ways a Command is instantiated (via the CLI and from the Network stack)
    # any Command initializer must support being called with zero parameters if it expects some.
    def initialize(*args)
    end

    # Set up the Message that needs to be created to send this Command
    # to the server to be processed. Used by the CLI. This method is given
    # the ClientFilter of which clients should respond to this message (if any) and
    # the extra arguments given on the command line.
    #
    # If work needs to be done prior to the network communication for CLI use,
    # override method to take care of that logic.
    #
    # The message returned here is then passed through the network to the appropriate
    # recipients (Clients, Server, or both) and used to trigger #perform on said
    # recipient.
    def prepare_message(options)
      to_message
    end

    # Run whatever this command needs to do.
    # All Command subclasses must implement this method.
    # If the message triggering this Command expects a response, the return
    # value of this method will be that response.
    def perform(message)
    end

    # When a message comes back from the server as a response to or because of
    # this command's #perform, the command object on the CLI will receive that
    # message here. This method will dispatch to either #receive_server_response
    # or #receive_client_response depending on the type of Command run.
    # In most cases, Commands should override the server/client specific receivers.
    # Only override this method to fully customize Message response handling.
    def receive_response(response)
      @response_tracker ||= TrackResponses.new
      @response_tracker.new_response(response)

      if @response_tracker.from_server?
        receive_server_response(response)
        finished
      elsif @response_tracker.from_client?
        receive_client_response(response)
        finished if @response_tracker.all_response_received?
      end
    end

    # Handle a response from a Server Command. Override this for specific handling
    # of Server Command responses.
    def receive_server_response(response)
      Pantry.ui.say("Server response:")
      Pantry.ui.say(response.body.inspect)
    end

    # Handle a response from a Client Command. This will be called for each Client
    # executing and responding to the requested Command.
    def receive_client_response(response)
      Pantry.ui.say("Response from #{response.from}:")
      Pantry.ui.say(response.body.inspect)
    end

    # Send a request out, returning the Future which will eventually
    # contain the response Message
    def send_request(message)
      @server_or_client.send_request(message)
    end

    # Send a request out and wait for the response. Will return the response
    # once it is received.
    #
    # This is a blocking call.
    def send_request!(message)
      send_request(message).value
    end

    # Create a new Message from the information in the current Command
    def to_message
      Pantry::Message.new(self.class.message_type)
    end

    # Blocking call that returns when the command has completed
    # Can be given a timeout (in seconds) to wait for a response
    def wait_for_finish(timeout = nil)
      completion_future.value(timeout)
    end

    # Notify all listeners that this command has completed its tasks
    def finished
      completion_future.signal(OpenStruct.new(:value => nil))
    end

    # Is this command finished?
    def finished?
      completion_future.ready?
    end

    def completion_future
      @completion_future ||= Celluloid::Future.new
    end
    protected :completion_future

    # The Type of this command, used to differentiate Messages.
    # Defaults to the full scope of the name, though with the special
    # case of removing any "Pantry" related scoping such as Pantry::
    # and Pantry::Commands::
    #
    # This value must be unique across the system or the messages will not
    # be processed reliably.
    #
    # Override this for a custom name.
    def self.message_type
      self.name.gsub(/Pantry::Commands::/, '').gsub(/Pantry::/, '')
    end

    # Set a link back to the Server or Client that's handling
    # this command. This will be set by the CommandHandler before calling
    # #perform.
    def server_or_client=(server_or_client)
      @server_or_client = server_or_client
    end
    alias client= server_or_client=
    alias server= server_or_client=

    # Get the server or client object handling this command
    def server_or_client
      @server_or_client
    end
    alias server server_or_client
    alias client server_or_client

    protected

    # Internal state tracking of server and client responses.
    # When a Client Command is triggered, the Server first responses with a message
    # containing the list of Clients who will execute the Command and respond.
    # Then we need to keep track of all the Clients who have responded so we know
    # when the command has fully finished across all Clients.
    class TrackResponses
      def initialize
        @expected_clients      = []
        @received_from_clients = []
      end

      def new_response(response)
        @latest_response = response

        if response[:client_response_list]
          @expected_clients = response.body
        elsif from_client?
          @received_from_clients << response
        end
      end

      def from_server?
        @latest_response.from_server? && !@latest_response[:client_response_list]
      end

      def from_client?
        !@latest_response.from_server?
      end

      def all_response_received?
        !@expected_clients.empty? && @expected_clients.length == @received_from_clients.length
      end
    end

  end

end
