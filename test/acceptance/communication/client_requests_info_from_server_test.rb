require 'acceptance/test_helper'

describe "Client requests information from the Server" do

  before do
    @server, @client1, @client2 = self.class.setup_environment
  end

  it "asks the server for information and waits for a response" do
    message = ServerEchoCommand.new("Hello Server").to_message
    response_future = @client1.send_request(message)

    assert_equal ["Hello Server"], response_future.value(2).body
  end

  it "handles multiple requests in the proper order" do
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
