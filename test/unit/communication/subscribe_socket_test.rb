require 'unit/test_helper'
require 'pantry/communication/subscribe_socket'

describe Pantry::Communication::SubscribeSocket do

  before do
    Celluloid.init

    Celluloid::ZMQ::SubSocket.any_instance.stubs(:linger=)
    Celluloid::ZMQ::SubSocket.any_instance.stubs(:connect)
    Celluloid::ZMQ::SubSocket.any_instance.stubs(:subscribe)
  end

  it "binds and subscribes to the given host and port" do
    Celluloid::ZMQ::SubSocket.any_instance.expects(:linger=).with(0)
    Celluloid::ZMQ::SubSocket.any_instance.expects(:connect).with("tcp://host:1235")
    Celluloid::ZMQ::SubSocket.any_instance.expects(:subscribe).with("")

    socket = Pantry::Communication::SubscribeSocket.new("host", 1235)
    socket.open
  end

  describe "subscription filtering" do
    it "subscribes to the stream according to filter options given" do
      socket = Pantry::Communication::SubscribeSocket.new("host", 1235)
      socket.filter_on(Pantry::Communication::MessageFilter.new(application: "pantry"))

      Celluloid::ZMQ::SubSocket.any_instance.expects(:subscribe).with("pantry")

      socket.open
    end

    it "subscribes to multiple streams to support nested scoping" do
      socket = Pantry::Communication::SubscribeSocket.new("host", 1235)
      socket.filter_on(Pantry::Communication::MessageFilter.new(
        application: "pantry", environment: "test"))

      Celluloid::ZMQ::SubSocket.any_instance.expects(:subscribe).with("pantry")
      Celluloid::ZMQ::SubSocket.any_instance.expects(:subscribe).with("pantry.test")

      socket.open
    end
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

    socket = Pantry::Communication::SubscribeSocket.new("host", 1235)
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
