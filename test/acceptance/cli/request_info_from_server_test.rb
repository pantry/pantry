require 'acceptance/test_helper'

describe "CLI can ask Server for information" do

  let(:cli) do
    cli = Pantry::CLI.new(identity: "test_client")
    cli.run
    cli
  end

  it "can ask for all known nodes" do
    set_up_environment(pub_sub_port: 10200, receive_port: 10201)

    filter = Pantry::Communication::ClientFilter.new

    # `pantry status`
    message = cli.request(filter, "status")

    identities = message.body.map {|e| e[:identity] }

    # May find any number of clients, including the CLI client, so just look
    # for a few we know should be there
    assert identities.include?(@client1.identity), "Response did not include the identity of Client 1"
    assert identities.include?(@client2.identity), "Response did not include the identity of Client 2"
  end

  it "can limit the query to a subset of clients" do
    set_up_environment(pub_sub_port: 10202, receive_port: 10203)

    client3 = Pantry::Client.new(application: "chatbot", identity: "client3")
    client3.run

    client4 = Pantry::Client.new(application: "chatbot", identity: "client4")
    client4.run

    filter = Pantry::Communication::ClientFilter.new(application: "chatbot")

    # `pantry chatbot status`
    message = cli.request(filter, "status")

    assert_equal 2, message.body.length
    assert_equal "client3", message.body[0][:identity]
    assert_equal "client4", message.body[1][:identity]

    client3.shutdown
    client4.shutdown
  end

end
