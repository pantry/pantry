module Pantry
  module Communication

    # Handles all serialization of Pantry::Messages to and from the ZeroMQ
    # communication stack
    class SerializeMessage

      # Convert a message into an array of message parts that will
      # be sent through ZeroMQ.
      def self.to_zeromq(message)
        ToZeromq.new(message).perform
      end

      class ToZeromq
        def initialize(message)
          @message = message
        end

        def perform
          [
            @message.to || "",
            @message.metadata.to_json,
            encode_message_body
          ].flatten.compact
        end

        protected

        def encode_message_body
          @message.body.map do |entry|
            case entry
            when Hash, Array
              entry.to_json
            else
              entry.to_s
            end
          end
        end
      end
    end
  end
end
