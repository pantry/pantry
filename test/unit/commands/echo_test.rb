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

end
