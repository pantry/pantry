require 'unit/test_helper'

describe Pantry::Commands::Echo do

  it "returns the body of the message received" do
    message = Pantry::Communication::Message.new("Echo")
    message << "This is a body"
    message << "Body part 2"

    command = Pantry::Commands::Echo.from_message(message)
    results = command.perform

    assert_equal ["This is a body", "Body part 2"], results
  end

  it "creates a message with the requested string" do
    command = Pantry::Commands::Echo.new("Hello World")
    message = command.to_message

    assert_equal "Hello World", message.body[0]
  end

end
