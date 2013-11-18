module Pantry
  module Commands

    # Simple Echo command, returns the body of the Message given.
    class Echo < Command

      def initialize(string_to_echo = "")
        @string_to_echo = string_to_echo
      end

      def perform
        @string_to_echo
      end

      def self.from_message(message)
        self.new(message.body[0])
      end

      def to_message
        message = super
        message << @string_to_echo
        message
      end

    end
  end
end
