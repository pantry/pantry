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

  it "by default is finished on receipt of a message" do
    command = Pantry::Command.new
    command.receive_response(Pantry::Message.new)
    # Will raise if blocked on the future
    command.wait_for_finish(1)

    assert command.finished?, "Command not marked as finished"
  end

  module Pantry
    module Commands
      class SubCommand < Pantry::Command
      end
    end
  end

  module Pantry
    module MyStuff
      class SubCommand < Pantry::Command
      end
    end
  end

  it "cleans up any known Pantry scoping when figuring out message type" do
    assert_equal "SubCommand", Pantry::Commands::SubCommand.message_type
    assert_equal "MyStuff::SubCommand", Pantry::MyStuff::SubCommand.message_type
  end

  module John
    module Pete
      class InnerClass < Pantry::Command
      end
    end
  end

  it "uses the full scoped name of the class" do
    command = John::Pete::InnerClass.new
    message = command.to_message

    assert_equal "John::Pete::InnerClass", message.type
  end

  class CustomNameCommand < Pantry::Command
    def self.message_type
      "Gir::WantsWaffles"
    end
  end

  it "allows custom command types" do
    command = CustomNameCommand.new
    message = command.to_message

    assert_equal "Gir::WantsWaffles", message.type
  end

  describe "#send_request!" do
    it "can send a request out and wait for the response" do
      client = Pantry::Client.new
      command = Pantry::Command.new
      command.client = client
      message = Pantry::Message.new
      response = Pantry::Message.new

      client.expects(:send_request).with(message).returns(mock(:value => response))

      assert_equal response, command.send_request!(message)
    end
  end

  describe "#send_request" do
    it "can send a request and return the future for async waiting" do
      client = Pantry::Client.new
      command = Pantry::Command.new
      command.client = client
      message = Pantry::Message.new

      client.expects(:send_request).with(message).returns("future")

      assert_equal "future", command.send_request(message)
    end
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
