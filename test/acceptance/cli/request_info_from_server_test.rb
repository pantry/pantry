require 'acceptance/test_helper'

describe "CLI can ask Server for information" do

  before do
    @server, @client1, @client2 = self.class.setup_environment
  end

  let(:cli) do
    cli = Pantry::CLI.new(identity: "test_client")
    cli.run
    cli
  end

  it "can ask for all known nodes" do
    filter = Pantry::Communication::ClientFilter.new

    # `pantry status`
    response = cli.request(filter, "status")
    message = response.message

    # May find any number of clients, including the CLI client, so just look
    # for a few we know should be there
    assert message.body.include?(@client1.identity), "Response did not include the identity of Client 1"
    assert message.body.include?(@client2.identity), "Response did not include the identity of Client 2"
  end

  it "can limit the query to a subset of clients" do
    client3 = Pantry::Client.new(application: "chatbot", identity: "client3")
    client3.run

    client4 = Pantry::Client.new(application: "chatbot", identity: "client4")
    client4.run

    filter = Pantry::Communication::ClientFilter.new(application: "chatbot")

    # `pantry chatbot status`
    response = cli.request(filter, "status")
    message = response.message

    assert_equal 2, message.body.length
    assert_equal "client3", message.body[0]
    assert_equal "client4", message.body[1]

    client3.shutdown
    client4.shutdown
  end

end
