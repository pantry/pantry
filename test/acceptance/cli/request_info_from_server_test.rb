require 'acceptance/test_helper'

describe "CLI can ask Server for information" do

  it "can ask for all known nodes" do
    set_up_environment(pub_sub_port: 10200, receive_port: 10201)

    listener = SaveInfoProgressListener.new
    cli = Pantry::CLI.new(identity: "test_client", progress_listener: listener)
    cli.run

    filter = Pantry::Communication::ClientFilter.new

    # `pantry status`
    cli.request(filter, "status")

    entries = listener.said.sort

    assert entries[0] =~ /#{@client1.identity}/, "Did not contain line for client1"
    assert entries[1] =~ /#{@client2.identity}/, "Did not contain line for client2"
  end

  it "can limit the query to a subset of clients" do
    set_up_environment(pub_sub_port: 10202, receive_port: 10203)

    listener = SaveInfoProgressListener.new
    cli = Pantry::CLI.new(identity: "test_client", progress_listener: listener)
    cli.run

    client3 = Pantry::Client.new(application: "chatbot", identity: "client3")
    client3.run

    client4 = Pantry::Client.new(application: "chatbot", identity: "client4")
    client4.run

    filter = Pantry::Communication::ClientFilter.new(application: "chatbot")

    sleep 1

    # `pantry chatbot status`
    cli.request(filter, "status")

    entries = listener.said.sort

    assert_equal 2, entries.length
    assert entries[0] =~ /client3/, "Did not contain line for client3"
    assert entries[1] =~ /client4/, "Did not contain line for client4"

    client3.shutdown
    client4.shutdown
  end

end
