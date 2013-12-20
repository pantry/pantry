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

    identities = listener.said[0].body.map {|e| e[:identity] }

    # May find any number of clients, including the CLI client, so just look
    # for a few we know should be there
    assert identities.include?(@client1.identity), "Response did not include the identity of Client 1"
    assert identities.include?(@client2.identity), "Response did not include the identity of Client 2"
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

    message = listener.said[0]

    assert_equal 2, message.body.length
    assert_equal "client3", message.body[0][:identity]
    assert_equal "client4", message.body[1][:identity]

    client3.shutdown
    client4.shutdown
  end

end
