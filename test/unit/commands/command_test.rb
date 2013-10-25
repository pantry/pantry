require 'unit/test_helper'
require 'pantry/commands/command'
require 'pantry/communication/message'

describe Pantry::Commands::Command do

  it "creates itself from a message" do
    message = Pantry::Communication::Message.new("Command")
    command = Pantry::Commands::Command.from_message(message)

    assert_nil command.perform
  end

  it "creates a message from itself" do
    command = Pantry::Commands::Command.new
    message = command.to_message

    assert_equal "Command", message.type
  end

  it "has a link back to the Server or Client handling the command" do
    command = Pantry::Commands::Command.new
    command.server_or_client = "client"

    assert_equal "client", command.server
    assert_equal "client", command.client
  end

  class SubCommand < Pantry::Commands::Command
  end

  it "uses the subclass name when figuring out the message type" do
    command = SubCommand.new
    message = command.to_message

    assert_equal "SubCommand", message.type
  end

  module John
    module Pete
      class InnerClass < Pantry::Commands::Command
      end
    end
  end

  it "drops any scope information from the name" do
    command = John::Pete::InnerClass.new
    message = command.to_message

    assert_equal "InnerClass", message.type
  end

end
