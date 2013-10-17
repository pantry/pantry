require 'unit/test_helper'
require 'pantry/client'
require 'pantry/communication/message'

describe Pantry::Client do

  before do
    Celluloid.init
  end

  it "sets up a subscribe socket for communication, closes it on shutdown" do
    client = Pantry::Client.new

    Pantry::Communication::SubscribeSocket.any_instance.expects(:add_listener).with(client)
    Pantry::Communication::SubscribeSocket.any_instance.expects(:open)
    Pantry::Communication::SubscribeSocket.any_instance.expects(:close)

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

end
