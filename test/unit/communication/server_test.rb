require 'unit/test_helper'

describe Pantry::Communication::Server do

  before do
    Pantry::Communication::PublishSocket.any_instance.stubs(:open)

    Pantry::Communication::ReceiveSocket.any_instance.stubs(:add_listener)
    Pantry::Communication::ReceiveSocket.any_instance.stubs(:open)

    Pantry::Communication::FileService.any_instance.stubs(:start_server)
  end

  it "opens a publish socket for communication" do
    Pantry::Communication::PublishSocket.any_instance.expects(:open)

    server = Pantry::Communication::Server.new(nil)
    server.run
  end

  it "opens a receive socket for communication" do
    server = Pantry::Communication::Server.new(nil)

    Pantry::Communication::ReceiveSocket.any_instance.expects(:add_listener).with(server)
    Pantry::Communication::ReceiveSocket.any_instance.expects(:open)

    server.run
  end

  it "starts up a local file service" do
    server = Pantry::Communication::Server.new(nil)

    Pantry::Communication::FileService.any_instance.expects(:start_server)

    server.run
  end

  describe "#publish_message" do
    let(:listener) { Pantry::Server.new }
    let(:msg) { Pantry::Message.new }
    let(:server)  { Pantry::Communication::Server.new(listener) }

    before do
      server.run
    end

    it "uses the publish socket to send messages to clients" do
      Pantry::Communication::PublishSocket.any_instance.expects(:send_message).with(msg)

      server.publish_message(msg)
    end

    it "sets the from of the message to the sender" do
      Pantry::Communication::PublishSocket.any_instance.expects(:send_message).with do |message|
        listener.identity == message.from
      end

      server.publish_message(msg)
    end
  end

  describe "Message forwarding" do
    let(:listener) { Pantry::Server.new }
    let(:msg) {
      m = Pantry::Message.new
      m.from = "client427"
      m
    }
    let(:server)  { Pantry::Communication::Server.new(listener) }

    before do
      server.run
    end

    it "publishes the message to connected clients untouched" do
      msg.to = "pantry"

      Pantry::Communication::PublishSocket.any_instance.expects(:send_message).with(msg)
      server.forward_message(msg)

      assert msg.forwarded?, "Message should have been marked as forwarded"
    end

    it "forwards off responses to forwarded messages" do
      msg.to = "client500"
      msg.forwarded!

      Pantry::Communication::PublishSocket.any_instance.expects(:send_message).with(msg)
      server.handle_message(msg)
    end
  end

  it "sends a message to a single client via identity, returning a future" do
    server = Pantry::Communication::Server.new(nil)
    server.run

    message = Pantry::Message.new("message")
    Pantry::Communication::PublishSocket.any_instance.expects(:send_message).with(message)

    future = server.send_request(message)

    assert_not_nil future
    assert_not future.ready?
  end

end
