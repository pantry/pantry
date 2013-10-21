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

  it "asks multiple clients for info and matches responses with requests" do
    @client1.on(:request_message) do |message|
      "Client 1 responds"
    end

    @client2.on(:request_message) do |message|
      "Client 2 responds"
    end

    message = Pantry::Communication::Message.new("request_message")
    future1 = @server.send_request(@client1.identity, message)
    future2 = @server.send_request(@client2.identity, message)

    Timeout::timeout(1) do
      assert_equal ["Client 1 responds"], future1.value.body
      assert_equal ["Client 2 responds"], future2.value.body
    end
  end

  it "handles multiple subsequent requests of the same type to the same client" do
    message_count = 0
    @client1.on(:request_message) do |message|
      "Client 1 responds #{message_count += 1}"
    end

    message = Pantry::Communication::Message.new("request_message")
    futures = []

    10.times do
      futures << @server.send_request(@client1.identity, message)
    end

    Timeout::timeout(5) do
      10.times do |i|
        assert_equal ["Client 1 responds #{i + 1}"], futures[i].value.body
      end

      assert_equal 10, message_count
    end
  end

end
