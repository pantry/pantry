require 'unit/test_helper'

describe Pantry::Commands::CommandHandler do

  let(:client)          { Pantry::Client.new(identity: "Test Client") }
  let(:command_handler) { Pantry::Commands::CommandHandler.new(client) }

  it "executes commands that match the message type" do
    command_handler.add_handler(:message_type) do |message|
      "Return Value"
    end

    message = Pantry::Communication::Message.new("message_type")
    response = command_handler.process(message)

    assert_equal "Return Value", response
  end

  it "ignores messages that don't match any command" do
    message = Pantry::Communication::Message.new("message_type")

    assert_nil command_handler.process(message)
  end

  class TestMessage < Pantry::Commands::Command
    def perform
      "Test message ran"
    end

    def self.from_message(message)
      self.new
    end
  end

  it "works with Command classes" do
    message = Pantry::Communication::Message.new("TestMessage")

    command_handler.add_command(TestMessage)
    output = command_handler.process(message)

    assert_equal "Test message ran", output
  end

  class ReturnClientIdentity < Pantry::Commands::Command
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

  class ReturnMessageIdentity < Pantry::Commands::Command
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

end
