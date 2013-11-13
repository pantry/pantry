require 'unit/test_helper'

describe Pantry::ServerCommands do

  it "is a command handler" do
    server = Pantry::Server.new
    commands = Pantry::ServerCommands.new(server)
    message = Pantry::Communication::Message.new("message_type")

    assert_nil commands.process(message)
  end

end
