require 'unit/test_helper'

describe Pantry::Commands::Status do

  mock_ui!

  describe "#prepare_message" do
    it "generates a message with the given client filter" do
      command = Pantry::Commands::Status.new
      message = command.prepare_message({
        application: "pantry"
      })

      assert_equal "Status", message.type
      assert_equal({application: "pantry", environment: nil, roles: [], identity: nil},
                  message.body[0])
    end
  end

  describe "#perform" do
    it "asks server for known clients and returns the info as a list" do
      server = Pantry::Server.new
      server.register_client(Pantry::ClientInfo.new(identity: "client1"))
      server.register_client(Pantry::ClientInfo.new(identity: "client2"))
      server.register_client(Pantry::ClientInfo.new(identity: "client3"))

      message = Pantry::Message.new("Status")

      command = Pantry::Commands::Status.new
      command.server_or_client = server

      response = command.perform(message)

      assert_equal ["client1", "client2", "client3"], response.map {|entry| entry[:identity] }
    end

    it "only counts clients that match the given filters" do
      server = Pantry::Server.new
      server.register_client(Pantry::ClientInfo.new(identity: "client1", application: "pantry"))
      server.register_client(Pantry::ClientInfo.new(identity: "client2", application: "pantry", environment: "testing"))
      server.register_client(Pantry::ClientInfo.new(identity: "client3"))

      message = Pantry::Message.new("Status")
      message << Pantry::Communication::ClientFilter.new(application: "pantry").to_hash

      command = Pantry::Commands::Status.new
      command.server_or_client = server

      response = command.perform(message)

      assert_equal ["client1", "client2"], response.map {|entry| entry[:identity] }
    end
  end

  describe "#receive_message" do
    let(:response) do
      Pantry::Message.new.tap do |m|
        m << {:identity => "client1", :last_checked_in => (Time.now - 60*60).to_s }
        m << {:identity => "client2", :last_checked_in => (Time.now - 60*5).to_s }
      end
    end

    it "reports the name and last time checked in to the user" do
      command = Pantry::Commands::Status.new
      command.receive_response(response)

      assert_match /client1/, stdout, "Did not include client1 in output"
      assert_match /client2/, stdout, "Did not include client2 in output"
    end

    it "builds a nice message for when the clients last checked in" do
      command = Pantry::Commands::Status.new
      command.receive_response(response)

      assert_match /5 minutes ago/, stdout
      assert_match /1 hour ago/, stdout
    end
  end

end
