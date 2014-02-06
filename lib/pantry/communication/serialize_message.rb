module Pantry
  module Communication

    # Handles all serialization of Pantry::Messages to and from the ZeroMQ
    # communication stack
    class SerializeMessage

      # To prevent accidents like trying to send the raw contents of a
      # JSON file and end up with a Ruby hash on the other side, we designate
      # messages as being JSON using a simple one character prefix. This way
      # we don't have to guess if it's JSON or not and will leave non encoded
      # strings alone. Don't want to dive into anything more complicated unless
      # it's really necessary (like msgpack).
      IS_JSON = '⁂'

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
              "#{IS_JSON}#{entry.to_json}"
            else
              entry.to_s
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
          body_parts.map do |raw_part|
            part = raw_part.force_encoding("UTF-8")

            if part.start_with?(IS_JSON)
              JSON.parse(part[1..-1], symbolize_names: true) rescue part
            else
              raw_part
            end
          end
        end
      end
    end
  end
end
