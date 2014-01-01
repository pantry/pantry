require 'acceptance/test_helper'

describe "Server requests info from the Client" do

  it "asks a client for info and waits for the response" do
    set_up_environment(ports_start_at: 10600)

    message = Pantry::Commands::Echo.new("Hello Client").to_message
    response_future = @server.send_request(@client1, message)

    assert_equal ["Hello Client"], response_future.value(1).body
  end

  it "asks multiple clients for info and matches responses with requests" do
    set_up_environment(ports_start_at: 10610)

    message1 = Pantry::Commands::Echo.new("Hello Client1").to_message
    message2 = Pantry::Commands::Echo.new("Hello Client2").to_message

    future1 = @server.send_request(@client1, message1)
    future2 = @server.send_request(@client2, message2)

    assert_equal ["Hello Client1"], future1.value(1).body
    assert_equal ["Hello Client2"], future2.value(1).body
  end

  it "handles multiple subsequent requests of the same type to the same client" do
    set_up_environment(ports_start_at: 10620)

    futures = []
    10.times do |i|
      message = Pantry::Commands::Echo.new("Hello Client #{i}").to_message
      futures << @server.send_request(@client1, message)
    end

    10.times do |i|
      assert_equal ["Hello Client #{i}"], futures[i].value(5).body
    end
  end

end
