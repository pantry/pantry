require 'unit/test_helper'

describe Pantry::Communication::Server do

  before do
    Pantry::Communication::PublishSocket.any_instance.stubs(:open)

    Pantry::Communication::ReceiveSocket.any_instance.stubs(:add_listener)
    Pantry::Communication::ReceiveSocket.any_instance.stubs(:open)
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

  describe "#publish_message" do
    let(:listener) { Pantry::Server.new }
    let(:message) { Pantry::Message.new }
    let(:server)  { Pantry::Communication::Server.new(listener) }

    before do
      server.run
    end

    it "uses the publish socket to send messages to clients" do
      Pantry::Communication::PublishSocket.any_instance.expects(:send_message).with(message)

      server.publish_message(message)
    end

    it "sets the from of the message to the sender" do
      Pantry::Communication::PublishSocket.any_instance.expects(:send_message).with do |message|
        listener.identity == message.from
      end

      server.publish_message(message)
    end
  end

  describe "Message forwarding" do
    let(:listener) { Pantry::Server.new }
    let(:message) {
      message = Pantry::Message.new
      message.from = "client427"
      message
    }
    let(:server)  { Pantry::Communication::Server.new(listener) }

    before do
      server.run
    end

    it "publishes the message to connected clients untouched" do
      message.to = "pantry"

      Pantry::Communication::PublishSocket.any_instance.expects(:send_message).with(message)
      server.forward_message(message)

      assert message.forwarded?, "Message should have been marked as forwarded"
    end

    it "forwards off responses to forwarded messages" do
      message.to = "client500"
      message.forwarded!

      Pantry::Communication::PublishSocket.any_instance.expects(:send_message).with(message)
      server.handle_message(message)
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

  describe "Receiving Files" do
    it "triggers a receiver actor and returns the UUID" do
      server = Pantry::Communication::Server.new(nil)

      uuid = server.receive_file("/tmp/path", 100, "abc123")

      assert_not_nil uuid
    end
  end

  describe "Sending Files" do
    it "triggers a send actor and returns the UUID" do
      server = Pantry::Communication::Server.new(nil)

      uuid = server.send_file(File.expand_path(__FILE__))

      assert_not_nil uuid
    end
  end
end
