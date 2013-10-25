require 'unit/test_helper'
require 'pantry/commands/client_commands'
require 'pantry/communication/message'
require 'pantry/client'

describe Pantry::Commands::ClientCommands do

  it "is a command handler" do
    client = Pantry::Client.new
    commands = Pantry::Commands::ClientCommands.new(client)
    message = Pantry::Communication::Message.new("message_type")

    assert_nil commands.process(message)
  end

end
