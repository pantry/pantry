module Pantry
  module Commands

    # Simple Echo command, returns the body of the Message given.
    class Echo < Command

#      cli "echo"

      def initialize(string_to_echo = "")
        @string_to_echo = string_to_echo

        @received = []
        @expected_clients  = []
      end

      def perform(message)
        @string_to_echo
      end

      def receive_response(message)
        if message.from_server?
          @expected_clients = message.body
        else
          @received << message
          progress_listener.say("#{message.from} echo's #{message.body[0].inspect}")
        end

        if !@expected_clients.empty? && @received.length >= @expected_clients.length
          progress_listener.finished
        end
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
