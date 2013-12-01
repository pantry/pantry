require 'unit/test_helper'

describe Pantry::Server do

  class FakeNetworkStack
    def initialize(listener)
    end

    def self.new_link(listener)
      new(listener)
    end
  end

  it "starts up the networking stack on run" do
    FakeNetworkStack.any_instance.expects(:run)

    server = Pantry::Server.new(FakeNetworkStack)
    server.run
  end

  describe "Client Registry" do

    it "can be given a Client to keep track of" do
      server = Pantry::Server.new
      client = Pantry::Client.new

      server.register_client(client)

      assert_equal [client], server.client_registry.all
    end

  end

  it "can publish messages to all clients" do
    server = Pantry::Server.new(FakeNetworkStack)
    message = Pantry::Message.new("test message")

    FakeNetworkStack.any_instance.expects(:publish_message).with do |message|
      message.to == ""
    end

    server.publish_message(message)
  end

  it "can publish messages to a filtered set of clients" do
    server = Pantry::Server.new(FakeNetworkStack)
    message = Pantry::Message.new("test message")
    filter = Pantry::Communication::ClientFilter.new(roles: %w(db))

    FakeNetworkStack.any_instance.expects(:publish_message).with do |message|
      message.to == "db"
    end

    server.publish_message(message, filter)
  end

  it "can request info of a specific client" do
    server = Pantry::Server.new(FakeNetworkStack)
    client = Pantry::Client.new(identity: "client1")
    message = Pantry::Message.new("test message")

    FakeNetworkStack.any_instance.expects(:send_request).with do |message|
      assert_equal "client1", message.to
    end

    server.send_request(client, message)

    assert message.requires_response?, "Message should require a response from the receiver"
  end

  it "executes callbacks when a message matches" do
    server = Pantry::Server.new

    Pantry::CommandHandler.any_instance.stubs(:can_handle?).returns(true)
    Pantry::CommandHandler.any_instance.expects(:process).with do |message|
      message.type == "test_message"
    end

    server.receive_message(Pantry::Message.new("test_message"))
  end

  it "builds and sends a response message if message flagged as needing one" do
    server = Pantry::Server.new(FakeNetworkStack)

    message = Pantry::Message.new("test_message")
    message.from = "client1"
    message.requires_response!

    Pantry::CommandHandler.any_instance.stubs(:can_handle?).returns(true)
    Pantry::CommandHandler.any_instance.expects(:process).returns("A response message")

    FakeNetworkStack.any_instance.expects(:publish_message).with do |response_message|
      assert_equal "test_message", response_message.type
      assert_equal message.from, response_message.to
      assert_equal ["A response message"], response_message.body
    end

    server.receive_message(message)
  end

  class ClientOnlyCommand < Pantry::Command
  end

  it "forwards an unhandleable command on to connected clients" do
    Pantry.add_client_command(ClientOnlyCommand)
    server = Pantry::Server.new(FakeNetworkStack)

    message = Pantry::Message.new("ClientOnlyCommand")
    message.from = "client1"
    message.requires_response!

    FakeNetworkStack.any_instance.expects(:forward_message).with(message)
    FakeNetworkStack.any_instance.expects(:publish_message).with do |message|
      message.to == "client1" && message.body == []
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
