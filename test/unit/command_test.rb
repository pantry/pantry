require 'unit/test_helper'

describe Pantry::Command do

  it "creates itself from a message" do
    message = Pantry::Message.new("Command")
    command = Pantry::Command.from_message(message)

    assert_nil command.perform(message)
  end

  it "creates a message from itself" do
    command = Pantry::Command.new
    message = command.to_message

    assert_equal "Command", message.type
  end

  it "has a link back to the Server or Client handling the command" do
    command = Pantry::Command.new
    command.server_or_client = "client"

    assert_equal "client", command.server
    assert_equal "client", command.client
  end

  it "can prepare itself as a Message to be sent down the pipe" do
    command = Pantry::Command.new
    filter = Pantry::Communication::ClientFilter.new
    message = command.prepare_message(filter)

    assert message.is_a?(Pantry::Message),
      "prepare_message returned the wrong value"
    assert_equal filter.stream, message.to
  end

  it "can continue processing any responses from #perform" do
    command = Pantry::Command.new
    fake_future = stub
    fake_future.stubs(:value).returns("a value")

    assert_equal "a value", command.handle_response(fake_future)
  end

  class SubCommand < Pantry::Command
  end

  it "uses the subclass name when figuring out the message type" do
    command = SubCommand.new
    message = command.to_message

    assert_equal "SubCommand", message.type
  end

  module John
    module Pete
      class InnerClass < Pantry::Command
      end
    end
  end

  it "drops any scope information from the name" do
    command = John::Pete::InnerClass.new
    message = command.to_message

    assert_equal "InnerClass", message.type
  end

  class CustomNameCommand < Pantry::Command
    def self.command_type
      "Gir::WantsWaffles"
    end
  end

  it "allows custom command types" do
    command = CustomNameCommand.new
    message = command.to_message

    assert_equal "Gir::WantsWaffles", message.type
  end

end
