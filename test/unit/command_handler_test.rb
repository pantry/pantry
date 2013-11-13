require 'unit/test_helper'

describe Pantry::CommandHandler do

  let(:client)          { Pantry::Client.new(identity: "Test Client") }
  let(:command_handler) { Pantry::CommandHandler.new(client) }

  class TestMessage < Pantry::Command
    def perform
      "Test message ran"
    end

    def self.from_message(message)
      self.new
    end
  end

  it "executes commands that match the message type" do
    message = Pantry::Communication::Message.new("TestMessage")

    command_handler.add_command(TestMessage)
    output = command_handler.process(message)

    assert_equal "Test message ran", output
  end

  it "ignores messages that don't match any command" do
    message = Pantry::Communication::Message.new("message_type")
    assert_nil command_handler.process(message)
  end

  it "knows if it can process a given command or not" do
    command_handler.add_command(TestMessage)

    message = Pantry::Communication::Message.new("unknown_type")
    assert_false command_handler.can_handle?(message), "Should not be able to handle unknown_type"

    message = Pantry::Communication::Message.new("TestMessage")
    assert command_handler.can_handle?(message), "Should be able to handle TestMessage"
  end

  class ReturnClientIdentity < Pantry::Command
    def perform
      self.client.identity
    end

    def self.from_message(message)
      self.new
    end
  end

  it "sets the server or client on the command before it's performed" do
    message = Pantry::Communication::Message.new("ReturnClientIdentity")

    command_handler.add_command(ReturnClientIdentity)
    response = command_handler.process(message)

    assert_equal "Test Client", response
  end

  class ReturnMessageIdentity < Pantry::Command
    def perform
      self.message
    end

    def self.from_message(message)
      self.new
    end
  end

  it "sets the server or client on the command before it's performed" do
    message = Pantry::Communication::Message.new("ReturnMessageIdentity")

    command_handler.add_command(ReturnMessageIdentity)
    response = command_handler.process(message)

    assert_equal message, response
  end

  it "can take a list of command classes on construction to handle" do
    handler = Pantry::CommandHandler.new(
      client, [TestMessage, ReturnClientIdentity, ReturnMessageIdentity])

    assert handler.can_handle?(Pantry::Communication::Message.new("TestMessage")),
      "Did not register TestMessage"
    assert handler.can_handle?(Pantry::Communication::Message.new("ReturnClientIdentity")),
      "Did not register ReturnClientIdentity"
    assert handler.can_handle?(Pantry::Communication::Message.new("ReturnMessageIdentity")),
      "Did not register ReturnMessageIdentity"
  end
end
