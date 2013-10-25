require 'acceptance/test_helper'

describe "CLI can ask Server for information" do

  before do
    @server, @client1, @client2 = self.class.setup_environment
  end

  it "can ask for all known nodes" do
    cli = Pantry::CLI.new

    # `pantry status`
    future = cli.request("status")

    response = Timeout::timeout(2) { future.value }

    # May find any number of clients, including the CLI client, so just look
    # for a few we know should be there
    assert response.body.include?(@client1.identity), "Response did not include the identity of Client 1"
    assert response.body.include?(@client2.identity), "Response did not include the identity of Client 2"
  end

  it "can limit the query to a subset of clients (application)" do
    client3 = Pantry::Client.new(application: "chatbot", identity: "client3")
    client3.run

    client4 = Pantry::Client.new(application: "chatbot", identity: "client4")
    client4.run

    # `pantry chatbot status`
    cli = Pantry::CLI.new(application: "chatbot")
    future = cli.request("status")

    response = Timeout::timeout(2) { future.value }

    assert_equal 2, response.body.length
    assert_equal "client3", response.body[0]
    assert_equal "client4", response.body[1]

    client3.shutdown
    client4.shutdown
  end

  it "can limit the query to a subset of clients (environment)"

  it "can limit the query to a subset of clients (roles)"

  it "handles commands that need their own arguments"
end
