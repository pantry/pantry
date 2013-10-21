require 'unit/test_helper'
require 'pantry/client'
require 'pantry/communication/client'

describe Pantry::Communication::Client do

  before do
    Celluloid.init

    Pantry::Communication::SubscribeSocket.any_instance.stubs(:open)
    Pantry::Communication::SubscribeSocket.any_instance.stubs(:close)

    Pantry::Communication::SendSocket.any_instance.stubs(:open)
    Pantry::Communication::SendSocket.any_instance.stubs(:close)
  end


  it "sets up a subscribe socket for communication, closes it on shutdown" do
    pantry_client = Pantry::Client.new
    client = Pantry::Communication::Client.new(pantry_client)

    Pantry::Communication::SubscribeSocket.any_instance.expects(:add_listener).with(client)
    Pantry::Communication::SubscribeSocket.any_instance.expects(:open)
    Pantry::Communication::SubscribeSocket.any_instance.expects(:close)

    client.run
    client.shutdown
  end

  it "configures filtering if the client has been given a scope" do
    pantry_client = Pantry::Client.new(
      application: "pantry", environment: "test",
        roles: %w(application database), identity: "client2"
    )

    client = Pantry::Communication::Client.new(pantry_client)

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

  it "sets up a Send socket for communication, closes it on shutdown" do
    pantry_client = Pantry::Client.new
    client = Pantry::Communication::Client.new(pantry_client)

    Pantry::Communication::SendSocket.any_instance.expects(:open)
    Pantry::Communication::SendSocket.any_instance.expects(:close)

    client.run
    client.shutdown
  end

  it "sends messages through the Send socket back to the server" do
    pantry_client = Pantry::Client.new
    client = Pantry::Communication::Client.new(pantry_client)
    message = Pantry::Communication::Message.new("message")

    Pantry::Communication::SendSocket.any_instance.expects(:send_message).with(message)

    client.run
    client.send_message(message)
  end
end
