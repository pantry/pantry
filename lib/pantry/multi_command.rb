module Pantry

  # A MultiCommand allows specifying multiple Commands to be run in succession.
  # Each command class given in .performs will have it's #perform executed and
  # the return values will be grouped together in a single return Message.
  #
  # It's currently expected that each Command executed is done when it's #perform
  # returns.
  class MultiCommand < Command

    # MultiCommand.performs takes a list of Command class constants.
    def self.performs(command_classes = [])
      @command_classes = command_classes
    end

    def self.command_classes
      @command_classes
    end

    # Iterate through each Command class and run that Command with the
    # given message. The results of each Command will be combined into a single
    # array return value and thus a single response Message back to the requester.
    def perform(message)
      Pantry.logger.debug("[#{client.identity}] Running MultiCommands")

      self.class.command_classes.map do |command_class|
        Pantry.logger.debug("[#{client.identity}] Running #{command_class}")
        command = command_class.new
        command.server_or_client = server_or_client
        command.perform(message)
      end
    end

  end

end
