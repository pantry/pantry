
module Pantry
  module Communication
    class Message

      attr_accessor :type

      attr_reader :body

      def initialize(message_type)
        @type = message_type
        @body = []
      end

      def <<(part)
        @body << part
      end

    end
  end
end
