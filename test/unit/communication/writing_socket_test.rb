require 'unit/test_helper'

describe Pantry::Communication::WritingSocket do

  class TestWriter < Pantry::Communication::WritingSocket
    attr_accessor :socket_impl

    def build_socket
      @socket_impl
    end
  end

  it "serializes a message and sends it down the pipe" do
    zmq_socket = Class.new do
      attr_accessor :written

      def write(message_body)
        @written = message_body
      end
    end.new

    writer = TestWriter.new("host", 1234)
    writer.socket_impl = zmq_socket
    writer.open

    message = Pantry::Message.new("message_type")
    message.to = "stream"
    message << "message_body_1"
    message << "message_body_2"

    writer.send_message(message)

    assert_equal(
      ["stream", message.metadata.to_json, "message_body_1", "message_body_2"],
      zmq_socket.written
    )
  end
end
