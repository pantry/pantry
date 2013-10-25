require 'unit/test_helper'
require 'pantry/server'
require 'pantry/client'

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

  describe "Client Registry" do

    it "can be given a Client to keep track of" do
      server = Pantry::Server.new
      client = Pantry::Client.new

      server.register_client(client)

      assert_equal [client], server.clients
    end

  end

  it "can publish messages to all clients" do
    server = Pantry::Server.new(FakeNetworkStack)
    message = Pantry::Communication::Message.new("test message")

    FakeNetworkStack.any_instance.expects(:publish_message).with(
      message, Pantry::Communication::ClientFilter.new
    )

    server.publish_message(message)
  end

  it "can publish messages to a filtered set of clients" do
    server = Pantry::Server.new(FakeNetworkStack)
    message = Pantry::Communication::Message.new("test message")
    filter = Pantry::Communication::ClientFilter.new(roles: %(db))

    FakeNetworkStack.any_instance.expects(:publish_message).with(message, filter)

    server.publish_message(message, filter)
  end

  it "can request info of a specific client" do
    server = Pantry::Server.new(FakeNetworkStack)
    message = Pantry::Communication::Message.new("test message")

    FakeNetworkStack.any_instance.expects(:send_request).with(
      message, Pantry::Communication::ClientFilter.new(identity: "client1")
    )

    server.send_request("client1", message)

    assert_equal server.identity, message.source
    assert message.requires_response?, "Message should require a response from the receiver"
  end

  it "executes callbacks when a message matches" do
    server = Pantry::Server.new

    test_message_called = false
    server.on(:test_message) do
      test_message_called = true
    end

    server.receive_message(Pantry::Communication::Message.new("test_message"))

    assert test_message_called, "Test message didn't trigger the callback"
  end

  it "builds and sends a response message if message flagged as needing one" do
    server = Pantry::Server.new(FakeNetworkStack)

    test_message_called = false
    server.on(:test_message) do
      test_message_called = true
      "A response message"
    end

    message = Pantry::Communication::Message.new("test_message")
    message.source = "client1"
    message.requires_response!

    FakeNetworkStack.any_instance.expects(:publish_message).with do |response_message, filter|
      assert_equal server.identity, response_message.source
      assert_equal "test_message", response_message.type
      assert_equal ["A response message"], response_message.body
      assert_equal "client1", filter.stream
    end

    server.receive_message(message)
  end

  describe "Identity" do
    it "can be given a specific identity" do
      s = Pantry::Server.new
      s.identity = "My Test Client"
      assert_equal "My Test Client", s.identity
    end

    it "defaults to the hostname of the machine" do
      s = Pantry::Server.new
      assert_equal `hostname`.strip, s.identity
    end
  end

end
