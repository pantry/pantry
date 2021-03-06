module Pantry

  # Manages and processes commands as requested from the Client or the Server.
  # Given a mapping of available commands, maps the incoming message to the appropriate
  # command handler and returns the response. Returns nil if no command found.
  class CommandHandler

    def initialize(server_or_client, commands_to_register = [])
      @handlers = {}
      @server_or_client = server_or_client

      commands_to_register.each do |command_class|
        add_command(command_class)
      end
    end

    # Install a Command class as a message handler for this process.
    # The Message's +type+ for this kind of message is simply the name of the class
    # without any scope information. E.g. Echo not Pantry::Command::Echo.
    def add_command(command_class)
      @handlers[command_class.message_type] = build_command_proc(command_class)
    end

    # Does this CommandHandler know how to handle the given command?
    def can_handle?(message)
      !@handlers[message.type].nil?
    end

    # Given a message, figure out which handler should be triggered and get things rolling
    def process(message)
      if handler = @handlers[message.type]
        Pantry.logger.debug("[#{@server_or_client.identity}] Running handler on #{message.inspect}")
        handler.call(message)
      else
        Pantry.logger.warn(
          "[#{@server_or_client.identity}] No known handler for message type #{message.type}"
        )
        nil
      end
    end

    protected

    def build_command_proc(command_class)
      proc do |message|
        command_obj = command_class.new
        command_obj.server_or_client = @server_or_client
        command_obj.perform(message)
      end
    end
  end

end
