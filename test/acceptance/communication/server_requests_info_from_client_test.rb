require 'acceptance/test_helper'

describe "Server requests info from the Client" do

  before do
    @server, @client1, @client2 = self.class.setup_environment
  end

  it "asks a client for info and waits for the response" do
    message = Pantry::Commands::Echo.new.to_message
    message << "Hello Client"
    response_future = @server.send_request(@client1, message)

    assert_equal ["Hello Client"], response_future.value(1).body
  end

  it "asks multiple clients for info and matches responses with requests" do
    message1 = Pantry::Commands::Echo.new.to_message
    message1 << "Hello Client1"

    message2 = Pantry::Commands::Echo.new.to_message
    message2 << "Hello Client2"

    future1 = @server.send_request(@client1, message1)
    future2 = @server.send_request(@client2, message2)

    assert_equal ["Hello Client1"], future1.value(1).body
    assert_equal ["Hello Client2"], future2.value(1).body
  end

  it "handles multiple subsequent requests of the same type to the same client" do
    futures = []
    10.times do |i|
      message = Pantry::Commands::Echo.new.to_message
      message << "Hello Client #{i}"
      futures << @server.send_request(@client1, message)
    end

    10.times do |i|
      assert_equal ["Hello Client #{i}"], futures[i].value(5).body
    end
  end

end
