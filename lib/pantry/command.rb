module Pantry

  # Base class of all Commands, this offers up some sane defaults for working
  # with Commands and their interactions with Messages.
  # All commands must implement #perform, which should return the values that
  # should be sent back to the requester.
  #
  # Command objects are responsible for the entire communication flow from the CLI
  # to the Server / Clients and back. This is managed through three methods:
  #
  #   prepare_message :: Builds the Message to send and can be used for any preparation
  #                      required before sending a Message
  #
  #   perform         :: The actual action of the given Command on the Recipient.
  #                      Any values returned from this function are packaged up and
  #                      sent back to the sender.
  #
  #   handle_response :: This method is given the response future object from sending
  #                      the message built in `prepare_message`. By default this just
  #                      returns the received Message but can be overridden to perform
  #                      any post-operation commands.
  #
  # Note: In normal CLI execution, #prepare_message and #handle_response are called
  # on the same object, but #prepare is called by another Actor elsewhere in the network.
  # Thus, if information needs to be made available to all three, #prepare_message can set
  # instance variables that #handle_response can read, but #perform must pull all information
  # out of the Message.
  class Command

    # The Message that triggered this Command
    attr_accessor :message

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
    def prepare_message(filter, arguments = [])
      message = to_message
      message.to = filter.stream
      message
    end

    # Run whatever this command needs to do.
    # All Command subclasses must implement this method.
    # If the message triggering this Command expects a response, the return
    # value of this method should be that response.
    def perform
    end

    # The original requester of this command can further handle any response messages
    # triggered by #perform with this message. This method is given the reqeust future which
    # will be filled by the Message from #perform.
    #
    # By default, this method simply returns the value the future is eventually filled with.
    # This currently has no timeout.
    #
    # HACK? If this method returns an object that responds to `receive_message`, it will be given
    # any further messages received by the CLI. See the Pantry::Commands::Echo and the MultiResponseHandler
    # for an example of how this works. TODO Is there a cleaner way of doing this?
    def handle_response(request_future)
      request_future.value(Pantry.config.response_timeout)
    end

    # Create a new Command from the given Message
    def self.from_message(message)
      self.new
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

    # Set a link back to the Server or Client that's handling
    # this command. This will be set by the CommandHandler before calling
    # #perform.
    def server_or_client=(server_or_client)
      @server_or_client = server_or_client
    end

    # Get the Server handling this command
    def server
      @server_or_client
    end

    # Get the Client handling this command
    def client
      @server_or_client
    end

  end

end
