require 'unit/test_helper'

describe Pantry::Command do

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
    message = command.prepare_message(filter, {})

    assert message.is_a?(Pantry::Message),
      "prepare_message returned the wrong value"
    assert_equal filter.stream, message.to
  end

  it "passes received message to the current listener and shuts down on received message" do
    command = Pantry::Command.new
    command.progress_listener.expects(:say)
    command.progress_listener.expects(:finished)

    command.receive_response(Pantry::Message.new)
  end

  it "builds a default progress listener if one isn't given" do
    command = Pantry::Command.new
    assert command.progress_listener.is_a?(Pantry::ProgressListener),
      "Default progress listener wasn't created"
  end

  it "can be given a specific progress listener" do
    command = Pantry::Command.new
    command.progress_listener = "listener!"
    assert_equal "listener!", command.progress_listener
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

  describe "CLI" do

    class CLICommand < Pantry::Command
      command "cli" do
        description "Sloppy"
      end
    end

    it "can configure CLI options and information" do
      assert_equal "cli", CLICommand.command_name
      assert_not_nil CLICommand.command_config, "No command config found"
    end

  end
end
