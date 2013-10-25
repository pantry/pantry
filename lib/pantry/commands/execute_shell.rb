module Pantry
  module Commands

    # Execute a Shell command, returning STDOUT, STDERR, and the status code.
    # Will not execute a sudo-d command, use ExecuteSudo instead.
    class ExecuteShell < Command

      def initialize(command, *arguments)
        @command   = command
        @arguments = arguments
      end

      def perform
        stdout, stderr, status = Open3.capture3(@command, *@arguments)
        [stdout, stderr, status.to_i]
      end

      def to_message
        message = super
        message << @command
        message << @arguments
        message
      end

      def self.from_message(message)
        self.new(message.body[0], *message.body[1..-1])
      end

    end

  end
end
