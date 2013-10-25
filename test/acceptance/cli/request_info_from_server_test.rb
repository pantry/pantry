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

    assert_equal @client1.identity, response.body[0]
    assert_equal @client2.identity, response.body[1]
  end

  it "can limit the query to a subset of clients (application)"

  it "can limit the query to a subset of clients (environment)"

  it "can limit the query to a subset of clients (roles)"

  it "handles commands that need their own arguments"
end
