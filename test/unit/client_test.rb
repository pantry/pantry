require 'unit/test_helper'

describe Pantry::Client do

  class FakeNetworkStack
    def initialize(listener)
    end

    def self.new_link(listener)
      new(listener)
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

  it "configures the client from Pantry.config if no options given" do
    with_custom_config do
      Pantry.config.client_identity = "identity"
      Pantry.config.client_application = "pantry"
      Pantry.config.client_environment = "test"
      Pantry.config.client_roles = ["app", "breaker"]

      client = Pantry::Client.new

      assert_equal "identity", client.identity
      assert_equal "pantry", client.application
      assert_equal "test", client.environment
      assert_equal ["app", "breaker"], client.roles
    end
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

    client = Pantry::Client.new(network_stack_class: FakeNetworkStack)
    client.run
  end

  it "sends a registration packet once networking is up" do
    client = Pantry::Client.new(identity: "johnson", network_stack_class: FakeNetworkStack)

    FakeNetworkStack.any_instance.stubs(:run)
    FakeNetworkStack.any_instance.expects(:send_message).with do |message|
      assert_equal "RegisterClient", message.type
    end

    client.run
  end

  it "executes callbacks when a message matches" do
    client = Pantry::Client.new

    Pantry::CommandHandler.any_instance.stubs(:can_handle?).returns(true)
    Pantry::CommandHandler.any_instance.expects(:process).with do |message|
      message.type == "test_message"
    end

    client.receive_message(Pantry::Communication::Message.new("test_message"))
  end

  it "builds and sends a response message if message flagged as needing one" do
    client = Pantry::Client.new(network_stack_class: FakeNetworkStack)

    Pantry::CommandHandler.any_instance.stubs(:can_handle?).returns(true)
    Pantry::CommandHandler.any_instance.expects(:process).returns("A response message")

    message = Pantry::Communication::Message.new("test_message")
    message.requires_response!

    FakeNetworkStack.any_instance.expects(:send_message).with do |response_message|
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
