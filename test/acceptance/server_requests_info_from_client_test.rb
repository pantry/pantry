require 'acceptance/test_helper'
require 'timeout'

describe "Server requests info from the Client" do

  before do
    @server, @client1, @client2 = self.class.setup_environment
  end

  it "asks a client for info and waits for the response" do
    @client1.on(:request_message) do |message|
      "Client 1 responds"
    end

    message = Pantry::Communication::Message.new("request_message")
    response_future = @server.send_request(@client1.identity, message)

    Timeout::timeout(1) do
      assert_equal ["Client 1 responds"], response_future.value.body
    end
  end

  it "asks multiple clients for info and matches responses with requests"

  it "receives information from all clients with the same identity"

end
