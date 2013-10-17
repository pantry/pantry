require 'unit/test_helper'
require 'pantry/communication/publish_socket'
require 'pantry/communication/message'

describe Pantry::Communication::PublishSocket do

  before do
    Celluloid.boot

    Celluloid::ZMQ::PubSocket.any_instance.stubs(:linger=)
    Celluloid::ZMQ::PubSocket.any_instance.stubs(:bind)
  end

  it "opens a ZMQ PubSocket, bound to host / port" do
    Celluloid::ZMQ::PubSocket.any_instance.expects(:linger=).with(0)
    Celluloid::ZMQ::PubSocket.any_instance.expects(:bind).with("tcp://host:1234")

    socket = Pantry::Communication::PublishSocket.new("host", 1234)
    socket.open
  end

  it "serializes a message and sends it down the pipe" do
    Celluloid::ZMQ::PubSocket.any_instance.expects(:write).with(
      ["", "message_type", "message_body_1", "message_body_2"]
    )

    socket = Pantry::Communication::PublishSocket.new("host", 1234)
    socket.open

    message = Pantry::Communication::Message.new("message_type")
    message << "message_body_1"
    message << "message_body_2"

    socket.send_message(message)
  end

  it "sends messages only to the streams specified in the filter" do
    filter = Pantry::Communication::MessageFilter.new(application: "pantry", environment: "test")

    Celluloid::ZMQ::PubSocket.any_instance.expects(:write).with(
      ["pantry.test", "message_type", "message_body_1", "message_body_2"]
    )

    socket = Pantry::Communication::PublishSocket.new("host", 1234)
    socket.open

    message = Pantry::Communication::Message.new("message_type")
    message << "message_body_1"
    message << "message_body_2"

    socket.send_message(message, filter)
  end
end
