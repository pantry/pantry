require 'acceptance/test_helper'

describe "Client requests information from the Server" do

  it "asks the server for information and waits for a response" do
    set_up_environment(pub_sub_port: 10300, receive_port: 10301)

    message = ServerEchoCommand.new("Hello Server").to_message
    response_future = @client1.send_request(message)

    assert_equal ["Hello Server"], response_future.value(2).body
  end

  it "handles multiple requests in the proper order" do
    set_up_environment(pub_sub_port: 10303, receive_port: 10304)

    futures = []
    10.times do |i|
      message = ServerEchoCommand.new("Hello Server #{i}").to_message
      futures << @client1.send_request(message)
    end

    futures.each_with_index do |future, idx|
      assert_equal ["Hello Server #{idx}"], future.value(1).body
    end
  end

end
