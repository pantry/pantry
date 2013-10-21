require 'unit/test_helper'
require 'pantry/server'

describe Pantry::Server do

  class FakeNetworkStack
    def initialize(listener)
    end
  end

  it "starts and stops the networking stack" do
    FakeNetworkStack.any_instance.expects(:run)
    FakeNetworkStack.any_instance.expects(:shutdown)

    server = Pantry::Server.new(FakeNetworkStack)
    server.run
    server.shutdown
  end

  it "can publish messages to all clients" do
    server = Pantry::Server.new(FakeNetworkStack)
    message = Pantry::Communication::Message.new("test message")

    FakeNetworkStack.any_instance.expects(:publish_message).with(
      message, Pantry::Communication::MessageFilter.new
    )

    server.publish_message(message)
  end

  it "can publish messages to a filtered set of clients" do
    server = Pantry::Server.new(FakeNetworkStack)
    message = Pantry::Communication::Message.new("test message")
    filter = Pantry::Communication::MessageFilter.new(roles: %(db))

    FakeNetworkStack.any_instance.expects(:publish_message).with(message, filter)

    server.publish_message(message, filter)
  end

  it "can request info of a specific client" do
    server = Pantry::Server.new(FakeNetworkStack)
    message = Pantry::Communication::Message.new("test message")

    FakeNetworkStack.any_instance.expects(:send_request).with(
      message, Pantry::Communication::MessageFilter.new(identity: "client1")
    )

    server.send_request("client1", message)

    assert message.requires_response?, "Message should require a response from the receiver"
  end

end
