require 'unit/test_helper'

describe Pantry::CLI do

  let(:filter) { Pantry::Communication::ClientFilter.new }

  class EmptyProgressListener < Pantry::ProgressListener
    def wait_for_finish
      self
    end
  end

  let(:listener) { EmptyProgressListener.new }

  def build_cli(command)
    Pantry::CLI.new [command].flatten, progress_listener: listener
  end

  it "defaults identity to the current ENV['USER']" do
    assert_equal ENV["USER"], build_cli("echo").identity
  end

  it "builds a message from a command request and sends it to the server" do
    cli = build_cli("status")

    cli.expects(:send_message).with do |message|
      assert_equal "ListClients", message.type
    end

    cli.run
  end

  it "passes along arguments to the command handler" do
    cli = build_cli(["echo", "Hello World"])

    cli.expects(:send_message).with do |message|
      assert message.requires_response?, "Message not flagged to require response"
      assert_equal "Echo", message.type
      assert_equal "Hello World", message.body[0]
    end

    cli.run
  end

  it "includes global options when passing options to a command handler" do
    cli = build_cli(["-a", "pantry", "-e", "test", "echo", "Hello World"])

    Pantry::Commands::Echo.any_instance.expects(:prepare_message).with do |filter, options|
      assert_equal "pantry", options["application"]
      assert_equal "test", options["environment"]
    end.returns(stub_everything)

    cli.stubs(:send_message)

    cli.run
  end

  it "sets the logging level to info on -v" do
    Pantry.config.expects(:refresh)

    capture_io do
      cli = build_cli(["-v"])
      cli.run
    end

    assert_equal :info, Pantry.config.log_level
  end

  it "sets logging level to debug on -d" do
    Pantry.config.expects(:refresh)

    capture_io do
      cli = build_cli(["-d"])
      cli.run
    end

    assert_equal :debug, Pantry.config.log_level
  end

  it "sets the hostname of the server to communicate with" do
    capture_io do
      cli = build_cli(["-h", "localhost"])
      cli.run
    end

    assert_equal "localhost", Pantry.config.server_host
  end

  it "prints out the version of pantry when requested" do
    out, err = capture_io do
      cli = build_cli(["-V"])
      cli.run
    end

    assert_equal Pantry::VERSION, out.strip
  end

  it "prints the help if nothing given on the command line" do
    out, err = capture_io do
      cli = build_cli([])
      cli.run
    end

    assert_match /Usage:/, out
  end

  it "can be given a set of filters to limit the request to a certain subset of clients" do
    cli = build_cli(["-a", "pantry", "-e", "test", "echo", "Hello World"])

    cli.expects(:send_message).with do |message|
      assert_equal "Echo", message.type
      assert_equal "pantry.test", message.to
    end

    cli.run
  end

  it "forwards other messages recieved to the current command" do
    cli = build_cli("status")
    cli.stubs(:send_message)

    command = Pantry::Command.new
    cli.request(filter, command, {})

    response = Pantry::Message.new
    response << "Hello World"

    listener.expects(:say).with do |message|
      assert message.body[0] == "Hello World"
    end

    cli.receive_message(response)
  end

end
