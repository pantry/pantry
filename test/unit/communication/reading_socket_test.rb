require 'unit/test_helper'
require 'pantry/communication/reading_socket'

describe Pantry::Communication::ReadingSocket do

  class TestSocket < Pantry::Communication::ReadingSocket
    attr_accessor :socket_impl
    attr_accessor :has_source_header

    def build_socket
      @socket_impl
    end

    def process_next_message
      @socket = @socket_impl
      super
    end

    def has_source_header?
      @has_source_header
    end
  end

  before do
    Celluloid.init
  end

  it "builds messages and passes each message to a listener" do
    zmq_socket = Class.new do
      def read
        @buffer ||= [
          "stream",
          {:type => "message_type", :source => nil, :requires_response => false}.to_json,
          "body part 1",
          "body part 2"
        ]
        @buffer.shift
      end

      def more_parts?
        @responses ||= [true, true, false]
        @responses.shift
      end
    end.new

    listener = Class.new do
      attr_reader :handled_message
      def handle_message(message)
        @handled_message = message
      end
    end.new

    reader = TestSocket.new("host", 1235)
    reader.add_listener(listener)
    reader.socket_impl = zmq_socket

    reader.process_next_message

    message = listener.handled_message
    assert_equal "stream", message.stream
    assert_equal "message_type", message.type
    assert_false message.requires_response?
    assert_equal ["body part 1", "body part 2"], message.body
  end

  it "ignores the first token (ZMQ source identity) if configured to do so" do
    zmq_socket = Class.new do
      def read
        @buffer ||= [
          "Source",
          "stream",
          {:type => "message_type", :source => nil, :requires_response => false}.to_json,
          "body part 1",
          "body part 2"
        ]
        @buffer.shift
      end

      def more_parts?
        @responses ||= [true, true, false]
        @responses.shift
      end
    end.new

    listener = Class.new do
      attr_reader :handled_message
      def handle_message(message)
        @handled_message = message
      end
    end.new

    reader = TestSocket.new("host", 1235)
    reader.has_source_header = true
    reader.add_listener(listener)
    reader.socket_impl = zmq_socket

    reader.process_next_message

    message = listener.handled_message
    assert_equal "stream", message.stream
    assert_equal "message_type", message.type
    assert_false message.requires_response?
    assert_equal ["body part 1", "body part 2"], message.body
  end

end
