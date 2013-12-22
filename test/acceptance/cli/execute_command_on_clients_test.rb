require 'acceptance/test_helper'

describe "CLI requests information from individual clients" do

  it "receives responses from each client asked" do
    set_up_environment(pub_sub_port: 10100, receive_port: 10101)

    listener = SaveInfoProgressListener.new
    cli = Pantry::CLI.new(
      ["-a", "pantry", "echo", "This is Neat"],
      identity: "cli1", progress_listener: listener
    )
    cli.run

    assert_equal [
      "#{@client1.identity} echo's \"This is Neat\"",
      "#{@client2.identity} echo's \"This is Neat\""
    ], listener.said.sort
  end

  it "can target specific clients for the commands sent" do
    set_up_environment(pub_sub_port: 10102, receive_port: 10103)

    listener = SaveInfoProgressListener.new
    cli = Pantry::CLI.new(
      ["-a", "pantry", "-e", "test", "-r", "app1", "echo", "This is Neat"],
      identity: "cli1", progress_listener: listener
    )
    cli.run

    assert_equal [
      "#{@client1.identity} echo's \"This is Neat\""
    ], listener.said
  end

end
