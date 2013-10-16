require 'acceptance/test_helper'

describe "Basic Server Client Communication" do

  before do
    Celluloid.boot
  end

  describe "Server" do
    it "can give a message to all connected clients" do
      Pantry.config.server_host = "127.0.0.1"
      Pantry.config.pub_sub_port = 10101

      server = Pantry::Server.new
      server.run

      client1 = Pantry::Client.new
      client1.run

      client2 = Pantry::Client.new
      client2.run

      client1_test_message = false
      client1.on(:test_message) do
        client1_test_message = true
      end

      client2_test_message = false
      client2.on(:test_message) do
        client2_test_message = true
      end

      # Ensure clients are registered
      sleep 1

      server.publish_to_clients("test_message")

      # Give communication time to happen
      sleep 1

      assert client1_test_message, "Client 1 did not get the message"
      assert client2_test_message, "Client 2 did not get the message"

      client1.shutdown
      client2.shutdown
      server.shutdown
    end

    it "can give a message to a subset of all connected clients"

    it "can request information from a specific client"

    it "can request information from specific clients"

#      server = Pantry::Server.new
#
#      client1 = Pantry::Client.new
#      client2 = Pantry::Client.new
#
#      sleep 1
#
#      server.publish_to_clients("this_is_a_test")
#
#      sleep 2
#
#      assert_equal ["this_is_a_test"], client1.messages
#      assert_equal ["this_is_a_test"], client2.messages
#
#      server.shutdown
#      client1.shutdown
#      client2.shutdown
#    end

    # PUB/SUB can also be used with a matcher so that only some clients
    # pick up the published event, will noodle on this. Will need to support
    # sending commands to and receiving responses from multiple clients at once
  end

  describe "Client" do
    it "can request information from the server"
  end

end
