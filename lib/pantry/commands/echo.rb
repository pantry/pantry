module Pantry
  module Commands

    # Simple Echo command, returns the body of the Message given.
    class Echo < Command

      def initialize(message = nil)
        @message = message
      end

      def perform
        message.body
      end

      def self.from_message(message)
        self.new(message)
      end

    end
  end
end
