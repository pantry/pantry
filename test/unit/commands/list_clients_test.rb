require 'unit/test_helper'

describe Pantry::Commands::ListClients do

  it "asks server for known clients and returns the info as a list" do
    server = Pantry::Server.new
    server.register_client(Pantry::Client.new(identity: "client1"))
    server.register_client(Pantry::Client.new(identity: "client2"))
    server.register_client(Pantry::Client.new(identity: "client3"))

    message = Pantry::Communication::Message.new("ListClients")

    command = Pantry::Commands::ListClients.from_message(message)
    command.server_or_client = server

    response = command.perform

    assert_equal ["client1", "client2", "client3"], response
  end

  it "only counts clients that match the given filters" do
    server = Pantry::Server.new
    server.register_client(Pantry::Client.new(identity: "client1", application: "pantry"))
    server.register_client(Pantry::Client.new(identity: "client2", application: "pantry", environment: "testing"))
    server.register_client(Pantry::Client.new(identity: "client3"))

    message = Pantry::Communication::Message.new("ListClients")
    message << Pantry::Communication::ClientFilter.new(application: "pantry").to_hash.to_json

    command = Pantry::Commands::ListClients.from_message(message)
    command.server_or_client = server

    response = command.perform

    assert_equal ["client1", "client2"], response
  end

  it "generates a message with the given client filter" do
    filter = Pantry::Communication::ClientFilter.new(application: "pantry")
    command = Pantry::Commands::ListClients.new(filter)

    message = command.to_message

    assert_equal "ListClients", message.type
    assert_equal filter.to_hash.to_json, message.body[0]
  end

end
