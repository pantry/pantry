require 'unit/test_helper'

describe Pantry::Commands::ExecuteShell do

  it "executes the command, returns stdout, stderr, and status code" do
    command = Pantry::Commands::ExecuteShell.new("hostname")
    stdout, stderr, status = command.perform

    assert_equal `hostname`, stdout
    assert_equal "", stderr
    assert_equal 0, status
  end

  it "passes any given arguments to the command" do
    command = Pantry::Commands::ExecuteShell.new("hostname", "-s")
    stdout, stderr, status = command.perform

    assert_equal `hostname -s`, stdout
    assert_equal "", stderr
    assert_equal 0, status
  end

  it "handles failed commands" do
    command = Pantry::Commands::ExecuteShell.new("hostname", "--invalid")
    stdout, stderr, status = command.perform

    assert_not_equal "", stderr
    assert status > 0, "Status should have been a failure (> 0)"
  end

  it "can build a message out of its options" do
    command = Pantry::Commands::ExecuteShell.new("hostname", "-s")
    message = command.to_message

    assert_not_nil message
    assert_equal "ExecuteShell", message.type
    assert_equal "hostname", message.body[0]
    assert_equal "-s", message.body[1]
  end

  it "can build itself out of a message" do
    message = Pantry::Communication::Message.new("execute_shell")
    message << "hostname"
    message << "-s"

    command = Pantry::Commands::ExecuteShell.from_message(message)
    stdout, stderr, status = command.perform

    assert_equal `hostname -s`, stdout
  end

end
