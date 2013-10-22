require 'unit/test_helper'
require 'pantry/commands/server_commands'
require 'pantry/communication/message'

describe Pantry::Commands::ServerCommands do

  it "is a command handler" do
    commands = Pantry::Commands::ServerCommands.new
    message = Pantry::Communication::Message.new("message_type")

    assert_nil commands.process(message)
  end

end
