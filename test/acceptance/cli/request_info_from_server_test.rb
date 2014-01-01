require 'acceptance/test_helper'

describe "CLI can ask Server for information" do

  it "can ask for all known nodes" do
    set_up_environment(ports_start_at: 10200)

    listener = SaveInfoProgressListener.new
    cli = Pantry::CLI.new(
      ["status"],
      identity: "test_client", progress_listener: listener
    )
    cli.run

    entries = listener.said.sort

    assert entries[0] =~ /#{@client1.identity}/, "Did not contain line for client1"
    assert entries[1] =~ /#{@client2.identity}/, "Did not contain line for client2"
  end

  it "can limit the query to a subset of clients" do
    set_up_environment(ports_start_at: 10210)

    listener = SaveInfoProgressListener.new
    cli = Pantry::CLI.new(
      ["-a", "chatbot", "status"],
      identity: "test_client", progress_listener: listener
    )

    client3 = Pantry::Client.new(application: "chatbot", identity: "client3")
    client3.run

    client4 = Pantry::Client.new(application: "chatbot", identity: "client4")
    client4.run

    cli.run

    entries = listener.said.sort
    assert_equal 2, entries.length
    assert entries[0] =~ /client3/, "Did not contain line for client3"
    assert entries[1] =~ /client4/, "Did not contain line for client4"

    client3.shutdown
    client4.shutdown
  end

end
