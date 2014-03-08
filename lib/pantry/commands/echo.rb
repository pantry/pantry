module Pantry
  module Commands

    # Simple Echo command, returns the body of the Message given.
    class Echo < Command

      command "echo MESSAGE" do
        description "Test Client communication with a simple Echo request"
      end

      def initialize(string_to_echo = "")
        @string_to_echo = string_to_echo
      end

      def to_message
        message = super
        message << @string_to_echo
        message
      end

      def perform(message)
        message.body[0]
      end

      def receive_client_response(response)
        Pantry.ui.say("#{response.from} echo's #{response.body[0].inspect}")
      end

    end

  end
end
