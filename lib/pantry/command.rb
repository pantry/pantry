module Pantry

  # Base class of all Commands, this offers up some sane defaults for working
  # with Commands and their interactions with Messages.
  # All commands must implement #perform, which should return the values that
  # should be sent back to the requester.
  class Command

    # Save the Message that triggered the creation of this Command
    attr_accessor :message

    # Run whatever this command needs to do.
    # All Command subclasses must implement this method.
    # If the message triggering this Command expects a response, the return
    # value of this method should be that response.
    def perform
    end

    # Create a new Command from the given Message
    def self.from_message(message)
      self.new
    end

    # Create a new Message from the information in the current Command
    def to_message
      Pantry::Communication::Message.new(self.class.command_type)
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
