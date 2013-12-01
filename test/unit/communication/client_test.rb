require 'unit/test_helper'

describe Pantry::Communication::Client do

  before do
    Pantry::Communication::SubscribeSocket.any_instance.stubs(:open)
    Pantry::Communication::SendSocket.any_instance.stubs(:open)
  end

  it "sets up a subscribe socket for communication" do
    pantry_client = Pantry::Client.new
    client = Pantry::Communication::Client.new(pantry_client)

    Pantry::Communication::SubscribeSocket.any_instance.expects(:add_listener).with(client)
    Pantry::Communication::SubscribeSocket.any_instance.expects(:open)

    client.run
  end

  it "configures filtering if the client has been given a scope" do
    pantry_client = Pantry::Client.new(
      application: "pantry", environment: "test",
        roles: %w(application database), identity: "client2"
    )

    client = Pantry::Communication::Client.new(pantry_client)

    Pantry::Communication::SubscribeSocket.any_instance.stubs(:add_listener)
    Pantry::Communication::SubscribeSocket.any_instance.stubs(:open)

    Pantry::Communication::SubscribeSocket.any_instance.expects(:filter_on).with(
      Pantry::Communication::ClientFilter.new(
        application: "pantry", environment: "test", roles: %w(application database),
        identity: "client2"
      )
    )

    client.run
  end

  it "sets up a Send socket for communication" do
    pantry_client = Pantry::Client.new
    client = Pantry::Communication::Client.new(pantry_client)

    Pantry::Communication::SendSocket.any_instance.expects(:open)

    client.run
  end

  it "sends messages through the Send socket back to the server" do
    pantry_client = Pantry::Client.new
    client = Pantry::Communication::Client.new(pantry_client)
    message = Pantry::Message.new("message")

    Pantry::Communication::SendSocket.any_instance.expects(:send_message).with(message)

    client.run
    client.send_message(message)
  end

  it "sets the source of the message to the current listener" do
    pantry_client = Pantry::Client.new
    client = Pantry::Communication::Client.new(pantry_client)
    message = Pantry::Message.new("message")

    Pantry::Communication::SendSocket.any_instance.expects(:send_message).with do |message|
      message.from == pantry_client.identity
    end

    client.run
    client.send_message(message)
  end

  it "sends a message to the server, returning a future" do
    pantry_client = Pantry::Client.new
    client = Pantry::Communication::Client.new(pantry_client)
    client.run

    message = Pantry::Message.new("message")
    Pantry::Communication::SendSocket.any_instance.expects(:send_message).with(message)

    future = client.send_request(message)

    assert_not_nil future
    assert_false   future.ready?
  end
end
