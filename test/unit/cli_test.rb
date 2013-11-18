require 'unit/test_helper'

describe Pantry::CLI do

  let(:filter) { Pantry::Communication::ClientFilter.new }

  before do
    Pantry::Client.any_instance.stubs(:run)
  end

  it "defaults identity to the current ENV['USER']" do
    cli = Pantry::CLI.new
    assert_equal ENV["USER"], cli.identity
  end

  it "builds a message from a command request and sends it to the server" do
    cli = Pantry::CLI.new

    cli.expects(:send_request).with do |message|
      assert_equal "ListClients", message.type
    end.returns(stub(:value => []))

    cli.request(filter, "status")
  end

  it "passes along arguments to the command handler" do
    cli = Pantry::CLI.new

    cli.expects(:send_request).with do |message|
      assert_equal "Echo", message.type
      assert_equal "Hello World", message.body[0]
    end.returns(stub(:value => []))

    cli.request(filter, "echo", "Hello World")
  end

  it "can be given a set of filters to limit the request to a certain subset of clients" do
    cli = Pantry::CLI.new

    filter = Pantry::Communication::ClientFilter.new(application: "pantry")

    cli.expects(:send_request).with do |message|
      assert_equal "Echo", message.type
      assert_equal "pantry", message.to
    end.returns(stub(:value => []))

    cli.request(filter, "echo", "Hello World")
  end

  it "treats all received messages as responses (does not execute commands)" do
    cli = Pantry::CLI.new

    message = Pantry::Communication::Message.new("Echo")
    message << "johnson"

    cli.receive_message(message)
    # Does not explode.
  end

end
