require 'unit/test_helper'

describe Pantry::CLI do

  let(:filter) { Pantry::Communication::ClientFilter.new }

  class EmptyProgressListener < Pantry::ProgressListener
    def wait_for_finish
      self
    end
  end

  let(:listener) { EmptyProgressListener.new }
  let(:cli)      { Pantry::CLI.new progress_listener: listener }

  it "defaults identity to the current ENV['USER']" do
    assert_equal ENV["USER"], cli.identity
  end

  it "builds a message from a command request and sends it to the server" do
    cli.expects(:send_message).with do |message|
      assert_equal "ListClients", message.type
    end

    cli.request(filter, "status")
  end

  it "passes along arguments to the command handler" do
    cli.expects(:send_message).with do |message|
      assert message.requires_response?, "Message not flagged to require response"
      assert_equal "Echo", message.type
      assert_equal "Hello World", message.body[0]
    end

    cli.request(filter, "echo", "Hello World")
  end

  it "can be given a set of filters to limit the request to a certain subset of clients" do
    filter = Pantry::Communication::ClientFilter.new(application: "pantry")

    cli.expects(:send_message).with do |message|
      assert_equal "Echo", message.type
      assert_equal "pantry", message.to
    end

    cli.request(filter, "echo", "Hello World")
  end

  it "forwards other messages recieved to the current command" do
    cli.stubs(:send_message)
    cli.request(filter, "echo", "Hello World")

    response = Pantry::Message.new
    response << "Hello World"

    listener.expects(:say).with do |message|
      assert message =~ /Hello World/, "Message #{message} did not match 'Hello World'"
    end

    cli.receive_message(response)
  end

end
