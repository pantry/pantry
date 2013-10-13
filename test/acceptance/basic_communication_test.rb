require 'acceptance/test_helper'

describe "Basic Server Client Communication" do

  describe "Server talking to Clients" do
    it "uses PUB/SUB to send messages to all clients" do
      server = Pantry::Server.new

      client1 = Pantry::Client.new
      client2 = Pantry::Client.new

      sleep 1

      server.publish_to_clients("this_is_a_test")

      assert_equal ["this_is_a_test"], client1.messages
      assert_equal ["this_is_a_test"], client2.messages
    end

    it "uses a REQ/REP to tell a single client to do work"

    # PUB/SUB can also be used with a matcher so that only some clients
    # pick up the published event, will noodle on this. Will need to support
    # sending commands to and receiving responses from multiple clients at once
  end

  describe "Client talking to the Server" do
    it "uses a REQ/REP to give the server information"
  end

end
