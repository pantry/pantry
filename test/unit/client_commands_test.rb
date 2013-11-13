require 'unit/test_helper'

describe Pantry::ClientCommands do

  it "is a command handler" do
    client = Pantry::Client.new
    commands = Pantry::ClientCommands.new(client)
    message = Pantry::Communication::Message.new("message_type")

    assert_nil commands.process(message)
  end

end
