require 'unit/test_helper'
require 'pantry/commands/client_commands'
require 'pantry/communication/message'

describe Pantry::Commands::ClientCommands do

  it "is a command handler" do
    commands = Pantry::Commands::ClientCommands.new
    message = Pantry::Communication::Message.new("message_type")

    assert_nil commands.process(message)
  end

end
