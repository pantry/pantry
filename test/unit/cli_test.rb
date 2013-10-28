require 'unit/test_helper'

describe Pantry::CLI do

  let(:filter) { Pantry::Communication::ClientFilter.new }

  before do
    Pantry::Client.any_instance.stubs(:run)
  end

  it "builds a message from a command request and sends it to the server" do
    cli = Pantry::CLI.new

    cli.expects(:send_request).with do |message|
      assert_equal "ListClients", message.type
    end

    cli.request(filter, "status")
  end

  it "passes along arguments to the command handler" do
    cli = Pantry::CLI.new

    cli.expects(:send_request).with do |message|
      assert_equal "ExecuteShell", message.type
      assert_equal "whoami", message.body[0]
    end

    cli.request(filter, "execute", "whoami")
  end

  it "can be given a set of filters to limit the request to a certain subset of clients" do
    cli = Pantry::CLI.new

    filter = Pantry::Communication::ClientFilter.new(application: "pantry")

    cli.expects(:send_request).with do |message|
      assert_equal "ExecuteShell", message.type
      assert_equal "pantry", message.to
    end

    cli.request(filter, "execute", "whoami")
  end

  it "treats all received messages as responses (does not execute commands)" do
    cli = Pantry::CLI.new

    message = Pantry::Communication::Message.new("ExecuteShell")
    message << "johnson"

    cli.receive_message(message)
    # Does not explode.
  end

end
