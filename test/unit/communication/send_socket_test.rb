require 'unit/test_helper'
require 'pantry/communication/send_socket'
require 'pantry/communication/message'

describe Pantry::Communication::SendSocket do

  before do
    Celluloid.boot

    Celluloid::ZMQ::DealerSocket.any_instance.stubs(:linger=)
    Celluloid::ZMQ::DealerSocket.any_instance.stubs(:connect)
  end

  it "opens a ZMQ DealerSocket, bound to host / port" do
    Celluloid::ZMQ::DealerSocket.any_instance.expects(:linger=).with(0)
    Celluloid::ZMQ::DealerSocket.any_instance.expects(:connect).with("tcp://host:1234")

    socket = Pantry::Communication::SendSocket.new("host", 1234)
    socket.open
  end

  it "serializes a message and sends it down the pipe" do
    Celluloid::ZMQ::DealerSocket.any_instance.expects(:write).with(
      ["", "message_type", "message_body_1", "message_body_2"]
    )

    socket = Pantry::Communication::SendSocket.new("host", 1234)
    socket.open

    message = Pantry::Communication::Message.new("message_type")
    message << "message_body_1"
    message << "message_body_2"

    socket.send_message(message)
  end

  it "sends messages only to the streams specified in the filter" do
    filter = Pantry::Communication::MessageFilter.new(application: "pantry", environment: "test")

    Celluloid::ZMQ::DealerSocket.any_instance.expects(:write).with(
      ["pantry.test", "message_type", "message_body_1", "message_body_2"]
    )

    socket = Pantry::Communication::SendSocket.new("host", 1234)
    socket.open

    message = Pantry::Communication::Message.new("message_type")
    message << "message_body_1"
    message << "message_body_2"

    socket.send_message(message, filter)
  end
end
