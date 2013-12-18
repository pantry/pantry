require 'unit/test_helper'

describe Pantry::Commands::Echo do

  it "returns the body of the message received" do
    message = Pantry::Message.new("Echo")
    message << "This is a body"

    command = Pantry::Commands::Echo.from_message(message)
    results = command.perform(message)

    assert_equal "This is a body", results
  end

  it "creates a message with the requested string" do
    command = Pantry::Commands::Echo.new("Hello World")
    message = command.to_message

    assert_equal "Hello World", message.body[0]
  end

end
