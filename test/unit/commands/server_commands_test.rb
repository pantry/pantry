require 'unit/test_helper'

describe Pantry::Commands::ServerCommands do

  it "is a command handler" do
    server = Pantry::Server.new
    commands = Pantry::Commands::ServerCommands.new(server)
    message = Pantry::Communication::Message.new("message_type")

    assert_nil commands.process(message)
  end

end
