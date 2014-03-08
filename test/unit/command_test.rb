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
    message = command.prepare_message({})

    assert message.is_a?(Pantry::Message),
      "prepare_message returned the wrong value"
  end

  describe "Response Handling" do
    describe "#receive_server_response" do
      class ServerCommand < Pantry::Command
        attr_reader :server_response
        def receive_server_response(response)
          @server_response = response
        end
      end

      before do
        @message = Pantry::Message.new
        @message.from = Pantry::SERVER_IDENTITY

        @command = ServerCommand.new
        @command.receive_response(@message)
      end

      it "is triggered by a non-client-list server message" do
        assert_equal @message, @command.server_response,
          "Did not triger the server response handler"
      end

      it "marks the command as finished" do
        assert @command.finished?
      end
    end

    describe "#receive_client_response" do
      let(:server_message) do
        Pantry::Message.new.tap do |sm|
          sm.from = Pantry::SERVER_IDENTITY
          sm[:client_response_list] = true
          sm << "client1"
          sm << "client2"
        end
      end

      class ClientCommand < Pantry::Command
        attr_reader :client_responses
        def receive_client_response(response)
          @client_responses ||= []
          @client_responses << response
        end
      end

      it "does not forward Server client_list message" do
        command = ClientCommand.new
        command.receive_response(server_message)

        assert_nil command.client_responses,
          "Should not have forwarded server client list message"
      end

      it "is triggered by Client responses" do
        client_message = Pantry::Message.new
        client_message.from = "client1"

        command = ClientCommand.new
        command.receive_response(client_message)

        assert_equal [client_message], command.client_responses,
          "Did not forward the client message to the handler"
      end

      it "does not mark the command as finished" do
        client_message = Pantry::Message.new
        client_message.from = "client1"

        command = ClientCommand.new
        command.receive_response(client_message)

        assert !command.finished?, "Command was improperly marked as finished"
      end

      it "marks the command as finished if all Clients have responded" do
        c1 = Pantry::Message.new
        c1.from = "client1"
        c2 = Pantry::Message.new
        c2.from = "client2"

        command = ClientCommand.new
        command.receive_response(server_message)
        command.receive_response(c1)
        command.receive_response(c2)

        assert_equal [c1, c2], command.client_responses
        assert command.finished?, "Command was not marked as finished after all responses"
      end
    end
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
