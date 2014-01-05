module Pantry

  # Base class of all Commands, this offers up some sane defaults for working
  # with Commands and their interactions with Messages.
  # All commands must implement #perform, which should return the values that
  # should be sent back to the requester.
  #
  # Command objects are responsible for the entire communication flow from the CLI
  # to the Server / Clients and back. This is managed through three methods:
  #
  #   prepare_message  :: Builds the Message to send and can be used for any preparation
  #                       required before sending a Message
  #
  #   perform          :: The actual action of the given Command on the Recipient.
  #                       Any values returned from this function are packaged up and
  #                       sent back to the sender.
  #
  #   receive_response :: All received responses due to the Command in question are sent
  #                       back into the command object on the CLI through this method.
  #
  # Note: In normal CLI execution, #prepare_message and #receive_response are called
  # on the same object, but #prepare is called by another Actor elsewhere in the network.
  # Thus, if information needs to be made available to all three, #prepare_message can set
  # instance variables that #receive_response can read, but #perform must pull all information
  # out of the Message.
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
    def prepare_message(filter, options)
      message = to_message
      message.to = filter.stream
      message
    end

    # Run whatever this command needs to do.
    # All Command subclasses must implement this method.
    # If the message triggering this Command expects a response, the return
    # value of this method will be that response.
    def perform(message)
    end

    # When a message comes back from the server as a response to or because of
    # this command's #perform, the command object on the CLI will receive that
    # message here. By default we just pass the message to the current listener
    # and makr ourselves finished.
    def receive_response(message)
      progress_listener.say(message)
      progress_listener.finished
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
      Pantry::Message.new(self.class.command_type)
    end

    # The Type of this command, used to differentiate Messages.
    # Defaults to the base class name, removing all scope information.
    # Override this for a custom name.
    def self.command_type
      self.name.split("::").last
    end

    # Set a specific Progress Listener object on this Command
    def progress_listener=(listener)
      @progress_listener = listener
    end

    # Retrieve the current progress listener
    def progress_listener
      @progress_listener ||= ProgressListener.new
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

  end

end
