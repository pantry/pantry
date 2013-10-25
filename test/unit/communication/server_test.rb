require 'unit/test_helper'
require 'pantry/communication/server'

describe Pantry::Communication::Server do

  before do
    Celluloid.init
    Pantry::Communication::PublishSocket.any_instance.stubs(:open)

    Pantry::Communication::ReceiveSocket.any_instance.stubs(:add_listener)
    Pantry::Communication::ReceiveSocket.any_instance.stubs(:open)
  end

  it "opens a publish socket for communication, closing it on shutdown" do
    Pantry::Communication::PublishSocket.any_instance.expects(:open)
    Pantry::Communication::PublishSocket.any_instance.expects(:close)

    server = Pantry::Communication::Server.new(nil)
    server.run
    server.shutdown
  end

  it "opens a receive socket for communication, closing it on shutdown" do
    server = Pantry::Communication::Server.new(nil)

    Pantry::Communication::ReceiveSocket.any_instance.expects(:add_listener).with(server)
    Pantry::Communication::ReceiveSocket.any_instance.expects(:open)
    Pantry::Communication::ReceiveSocket.any_instance.expects(:close)

    server.run
    server.shutdown
  end

  it "uses the publish socket to send messages to clients" do
    server = Pantry::Communication::Server.new(nil)
    server.run

    Pantry::Communication::PublishSocket.any_instance.expects(:send_message).with(
      "message", Pantry::Communication::ClientFilter.new)

    server.publish_message("message", Pantry::Communication::ClientFilter.new)
  end

  it "passes down a given ClientFilter to the socket" do
    server = Pantry::Communication::Server.new(nil)
    server.run

    filter = Pantry::Communication::ClientFilter.new
    Pantry::Communication::PublishSocket.any_instance.expects(:send_message).with("message", filter)

    server.publish_message("message", filter)
  end

  it "sends a message to a single client via identity, returning a future" do
    server = Pantry::Communication::Server.new(nil)
    server.run

    filter = Pantry::Communication::ClientFilter.new(identity: "client1")
    message = Pantry::Communication::Message.new("message")
    Pantry::Communication::PublishSocket.any_instance.expects(:send_message).with(message, filter)

    future = server.send_request(message, filter)

    assert_not_nil future
    assert_not future.ready?
  end
end
