require 'acceptance/test_helper'

describe "Client requests information from the Server" do

  before do
    @server, @client1, @client2 = self.class.setup_environment
  end

  it "asks the server for information and waits for a response" do
    @server.on(:client_info) do |message|
      "Server responds"
    end

    message = Pantry::Communication::Message.new("client_info")
    response_future = @client1.send_request(message)

    assert_equal ["Server responds"], response_future.value(2).body
  end

  it "handles multiple requests in the proper order" do
    response_count = 0
    @server.on(:client_info) do |message|
      "Server responds #{response_count += 1}"
    end

    message = Pantry::Communication::Message.new("client_info")
    futures = []
    10.times do
      futures << @client1.send_request(message)
    end

    futures.each_with_index do |future, idx|
      assert_equal ["Server responds #{idx + 1}"], future.value(1).body
    end
  end

end
