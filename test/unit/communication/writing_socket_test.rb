require 'unit/test_helper'
require 'pantry/communication/message'
require 'pantry/communication/writing_socket'

describe Pantry::Communication::WritingSocket do

  class TestWriter < Pantry::Communication::WritingSocket
    attr_accessor :socket_impl

    def build_socket
      @socket_impl
    end
  end

  before do
    Celluloid.init

    @zmq_socket = Class.new do
      attr_accessor :written

      def write(message_body)
        @written = message_body
      end
    end.new

    @writer = TestWriter.new("host", 1234)
    @writer.socket_impl = @zmq_socket
    @writer.open
  end

  it "serializes a message and sends it down the pipe" do
    message = Pantry::Communication::Message.new("message_type")
    message << "message_body_1"
    message << "message_body_2"

    @writer.send_message(message)

    assert_equal(
      ["", message.metadata.to_json, "message_body_1", "message_body_2"],
      @zmq_socket.written
    )
  end

  it "sends messages only to the streams specified in the filter" do
    filter = Pantry::Communication::MessageFilter.new(application: "pantry", environment: "test")

    message = Pantry::Communication::Message.new("message_type")
    message << "message_body_1"
    message << "message_body_2"

    @writer.send_message(message, filter)

    assert_equal(
      ["pantry.test", message.metadata.to_json, "message_body_1", "message_body_2"],
      @zmq_socket.written
    )
  end
end
