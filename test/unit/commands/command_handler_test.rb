require 'unit/test_helper'
require 'pantry/commands/command_handler'
require 'pantry/communication/message'

describe Pantry::Commands::CommandHandler do

  it "executes commands that match the message type" do
    commands = Pantry::Commands::CommandHandler.new
    commands.add_handler(:message_type) do |message|
      "Return Value"
    end

    message = Pantry::Communication::Message.new("message_type")
    response = commands.process(message)

    assert_equal "Return Value", response
  end

  it "ignores messages that don't match any command" do
    commands = Pantry::Commands::CommandHandler.new
    message = Pantry::Communication::Message.new("message_type")

    assert_nil commands.process(message)
  end

  class TestMessage
    def perform
      "Test message ran"
    end

    def self.from_message(message)
      self.new
    end
  end

  it "works with Command classes" do
    commands = Pantry::Commands::CommandHandler.new
    message = Pantry::Communication::Message.new("TestMessage")

    commands.add_command(TestMessage)
    output = commands.process(message)

    assert_equal "Test message ran", output
  end

end
