require 'unit/test_helper'
require 'pantry/client'
require 'pantry/communication/message'

describe Pantry::Client do

  class FakeNetworkStack
    def initialize(listener)
    end
  end

  before do
    FakeNetworkStack.any_instance.stubs(:send_message)
  end

  it "can take a list of roles this Client manages" do
    client = Pantry::Client.new roles: %w(app db)
    assert_equal %w(app db), client.roles
  end

  it "can take an application to manage" do
    client = Pantry::Client.new application: "pantry"
    assert_equal "pantry", client.application
  end

  it "can take an environment to manage" do
    client = Pantry::Client.new environment: "production"
    assert_equal "production", client.environment
  end

  it "packages up all filter information into a Filter object" do
    client = Pantry::Client.new environment: "production", application: "pantry"

    filter = Pantry::Communication::ClientFilter.new(
      environment: "production", application: "pantry", identity: client.identity)

    assert_equal filter, client.filter
    assert_equal "production", client.environment
  end

  it "starts up and shuts down the networking stack" do
    FakeNetworkStack.any_instance.expects(:run)
    FakeNetworkStack.any_instance.expects(:shutdown)

    client = Pantry::Client.new(network_stack_class: FakeNetworkStack)
    client.run
    client.shutdown
  end

  it "sends a registration packet once networking is up" do
    client = Pantry::Client.new(identity: "johnson", network_stack_class: FakeNetworkStack)

    FakeNetworkStack.any_instance.stubs(:run)
    FakeNetworkStack.any_instance.expects(:send_message).with do |message|
      assert_equal "RegisterClient", message.type
      assert_equal client.identity, message.source
    end

    client.run
  end

  it "executes callbacks when a message matches" do
    client = Pantry::Client.new

    test_message_called = false
    client.on(:test_message) do
      test_message_called = true
    end

    client.receive_message(Pantry::Communication::Message.new("test_message"))

    assert test_message_called, "Test message didn't trigger the callback"
  end

  it "builds and sends a response message if message flagged as needing one" do
    client = Pantry::Client.new(network_stack_class: FakeNetworkStack)

    test_message_called = false
    client.on(:test_message) do
      test_message_called = true
      "A response message"
    end

    message = Pantry::Communication::Message.new("test_message")
    message.requires_response!

    FakeNetworkStack.any_instance.expects(:send_message).with do |response_message|
      assert_equal client.identity, response_message.source
      assert_equal "test_message", response_message.type
      assert_equal ["A response message"], response_message.body
    end

    client.receive_message(message)
  end

  it "can request info of a the server" do
    client = Pantry::Client.new(network_stack_class: FakeNetworkStack)
    message = Pantry::Communication::Message.new("test message")

    FakeNetworkStack.any_instance.expects(:send_request).with(message)

    client.send_request( message)

    assert message.requires_response?, "Message should require a response from the server"
    assert_equal client.identity, message.source
  end

  describe "Identity" do
    it "can be given a specific identity" do
      c = Pantry::Client.new identity: "My Test Client"
      assert_equal "My Test Client", c.identity
    end

    it "defaults to the hostname of the machine" do
      c = Pantry::Client.new
      assert_equal `hostname`.strip, c.identity
    end
  end

end
