require 'unit/test_helper'
require 'pantry/client'
require 'pantry/communication/message'

describe Pantry::Client do

  before do
    Celluloid.init
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

  it "sets up a subscribe socket for communication, closes it on shutdown" do
    client = Pantry::Client.new

    Pantry::Communication::SubscribeSocket.any_instance.expects(:add_listener).with(client)
    Pantry::Communication::SubscribeSocket.any_instance.expects(:open)
    Pantry::Communication::SubscribeSocket.any_instance.expects(:close)

    client.run
    client.shutdown
  end

  it "configures filtering if the client has been given a scope" do
    client = Pantry::Client.new application: "pantry", environment: "test",
      roles: %w(application database), identity: "client2"

    Pantry::Communication::SubscribeSocket.any_instance.stubs(:add_listener)
    Pantry::Communication::SubscribeSocket.any_instance.stubs(:open)
    Pantry::Communication::SubscribeSocket.any_instance.stubs(:close)

    Pantry::Communication::SubscribeSocket.any_instance.expects(:filter_on).with(
      Pantry::Communication::MessageFilter.new(
        application: "pantry", environment: "test", roles: %w(application database),
        identity: "client2"
      )
    )

    client.run
    client.shutdown
  end

  it "executes callbacks when a message matches" do
    client = Pantry::Client.new

    test_message_called = false
    client.on(:test_message) do
      test_message_called = true
    end

    client.handle_message(Pantry::Communication::Message.new("test_message"))

    assert test_message_called, "Test message didn't trigger the callback"
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
