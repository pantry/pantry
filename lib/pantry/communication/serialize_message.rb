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

      # Given an array of message parts from ZeroMQ, built up a Pantry::Message
      # containing the included information.
      def self.from_zeromq(parts)
        FromZeromq.new(parts).perform
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

    class FromZeromq
      def initialize(parts)
        @parts = parts
      end

      def perform
        Pantry::Message.new.tap do |message|
          message.metadata = JSON.parse(@parts[1], symbolize_names: true)
          message.to       = @parts[0]
          message.body     = parse_body_parts(@parts[2..-1])
        end
      end

      protected

      def parse_body_parts(body_parts)
        body_parts.map do |part|
          # This may not be the best way but want to guess at a string being
          # JSON without actually parsing it. I don't think this will be
          # much of a problem as we have full control over message encoding.
          if part.start_with?('{', '[')
            JSON.parse(part, symbolize_names: true)
          else
            part
          end
        end
      end
    end
  end
end
