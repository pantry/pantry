require 'acceptance/test_helper'

describe "Pub/Sub Communication" do

  before do
    @server, @client1, @client2 = self.class.setup_environment
  end

  describe "Server" do
    it "can publish a message to all connected clients" do
      @server.publish_message(
        Pantry::Communication::Message.new("test_message"),
        Pantry::Communication::ClientFilter.new(application: "pantry")
      )

      # Give communication time to happen
      sleep 1

      assert_equal "test_message", @client1.last_received_message.type
      assert_equal "test_message", @client2.last_received_message.type
    end

    it "can publish a message to a subset of all connected clients" do
      client3 = Pantry::Client.new(roles: %w(database), identity: "client3")
      client3.run

      client4 = Pantry::Client.new(roles: %w(database task), identity: "client4")
      client4.run

      sleep 1

      @server.publish_message(Pantry::Communication::Message.new("to_databases"),
                              Pantry::Communication::ClientFilter.new(roles: %w(database)))

      # Give communication time to happen
      sleep 1

      assert_equal "to_databases", client3.last_received_message.type
      assert_equal "to_databases", client4.last_received_message.type

      @server.publish_message(Pantry::Communication::Message.new("to_tasks"),
                              Pantry::Communication::ClientFilter.new(roles: %w(task)))

      # Give communication time to happen
      sleep 1

      assert_equal "to_tasks", client4.last_received_message.type

      client3.shutdown
      client4.shutdown
    end
  end
end
