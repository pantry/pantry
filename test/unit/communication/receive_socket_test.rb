require 'unit/test_helper'
require 'pantry/communication/receive_socket'

describe Pantry::Communication::ReceiveSocket do

  before do
    Celluloid.init

    Celluloid::ZMQ::RouterSocket.any_instance.stubs(:bind)
  end

  it "binds and subscribes to the given host and port" do
    Celluloid::ZMQ::RouterSocket.any_instance.expects(:bind).with("tcp://host:4567")

    socket = Pantry::Communication::ReceiveSocket.new("host", 4567)
    socket.open
  end

  it "builds messages and passes each message to a listener" do
    zmq_socket = Class.new do
      def read
        @buffer ||= ["stream", "message_type", "body part 1", "body part 2"]
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

    socket = Pantry::Communication::ReceiveSocket.new("host", 4567)
    socket.add_listener(listener)
    socket.instance_variable_set("@socket", zmq_socket)

    # Only because we need to work around Celluloid async here. May look at
    # another layer of refactoring but I don't think it's worth the effort right now
    socket.send("process_next_message")

    message = listener.handled_message
    assert_equal "stream", message.stream
    assert_equal "message_type", message.type
    assert_equal ["body part 1", "body part 2"], message.body
  end


end
