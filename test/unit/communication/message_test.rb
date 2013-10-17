require 'unit/test_helper'
require 'pantry/communication/message'

describe Pantry::Communication::Message do

  it "takes a message type in constructor" do
    message = Pantry::Communication::Message.new("message_type")
    assert_equal "message_type", message.type
  end

  it "can be given strings for the body parts" do
    message = Pantry::Communication::Message.new("type")
    message << "Part 1"
    message << "Part 2"

    assert_equal ["Part 1", "Part 2"], message.body
  end

end