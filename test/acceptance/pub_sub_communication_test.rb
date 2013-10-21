require 'acceptance/test_helper'

describe "Pub/Sub Communication" do

  before do
    @server, @client1, @client2 = self.class.setup_environment
  end

  describe "Server" do
    it "can publish a message to all connected clients" do
      client1_test_message = false
      @client1.on(:test_message) do |message|
        client1_test_message = true
      end

      client2_test_message = false
      @client2.on(:test_message) do |message|
        client2_test_message = true
      end

      @server.publish_message(Pantry::Communication::Message.new("test_message"))

      # Give communication time to happen
      sleep 1

      assert client1_test_message, "Client 1 did not get the message"
      assert client2_test_message, "Client 2 did not get the message"
    end

    it "can publish a message to a subset of all connected clients" do
      client3 = Pantry::Client.new(roles: %w(database))
      client3.run

      client4 = Pantry::Client.new(roles: %w(database task))
      client4.run

      client3_test_messages = []
      client3.on(:test_message) do |message|
        client3_test_messages << message
      end

      client4_test_messages = []
      client4.on(:test_message) do |message|
        client4_test_messages << message
      end

      @server.publish_message(Pantry::Communication::Message.new("test_message"),
                              Pantry::Communication::MessageFilter.new(roles: %w(database)))
      @server.publish_message(Pantry::Communication::Message.new("test_message"),
                              Pantry::Communication::MessageFilter.new(roles: %w(task)))

      # Give communication time to happen
      sleep 1

      assert_equal "test_message", client3_test_messages.first.type
      assert_equal ["test_message", "test_message"], client4_test_messages.map(&:type)
    end
  end
end
