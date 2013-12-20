require 'unit/test_helper'

describe Pantry::Commands::ListClients do

  it "asks server for known clients and returns the info as a list" do
    server = Pantry::Server.new
    server.register_client(Pantry::Client.new(identity: "client1"))
    server.register_client(Pantry::Client.new(identity: "client2"))
    server.register_client(Pantry::Client.new(identity: "client3"))

    message = Pantry::Message.new("ListClients")

    command = Pantry::Commands::ListClients.new
    command.server_or_client = server

    response = command.perform(message)

    assert_equal ["client1", "client2", "client3"], response.map {|entry| entry[:identity] }
  end

  it "only counts clients that match the given filters" do
    server = Pantry::Server.new
    server.register_client(Pantry::Client.new(identity: "client1", application: "pantry"))
    server.register_client(Pantry::Client.new(identity: "client2", application: "pantry", environment: "testing"))
    server.register_client(Pantry::Client.new(identity: "client3"))

    message = Pantry::Message.new("ListClients")
    message << Pantry::Communication::ClientFilter.new(application: "pantry").to_hash

    command = Pantry::Commands::ListClients.new
    command.server_or_client = server

    response = command.perform(message)

    assert_equal ["client1", "client2"], response.map {|entry| entry[:identity] }
  end

  it "reports the name and last time checked in to the listener" do
    response = Pantry::Message.new
    client1_check_in = Time.now - 60 * 60
    client2_check_in = Time.now - 60 * 5
    response << {:identity => "client1", :last_checked_in => client1_check_in }
    response << {:identity => "client2", :last_checked_in => client2_check_in }

    command = Pantry::Commands::ListClients.new

    command.progress_listener = mock
    command.progress_listener.expects(:say).times(2)
    command.progress_listener.expects(:finished)

    command.receive_response(response)
  end

  it "generates a message with the given client filter" do
    filter = Pantry::Communication::ClientFilter.new(application: "pantry")
    command = Pantry::Commands::ListClients.new
    message = command.prepare_message(filter)

    assert_equal "ListClients", message.type
    assert_equal filter.to_hash, message.body[0]
  end

end
