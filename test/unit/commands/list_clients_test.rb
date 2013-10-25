require 'unit/test_helper'
require 'pantry/server'
require 'pantry/client'
require 'pantry/commands/list_clients'

describe Pantry::Commands::ListClients do

  it "asks server for known clients and returns the info as a list" do
    server = Pantry::Server.new
    server.register_client(Pantry::Client.new(identity: "client1"))
    server.register_client(Pantry::Client.new(identity: "client2"))
    server.register_client(Pantry::Client.new(identity: "client3"))

    command = Pantry::Commands::ListClients.new
    command.server_or_client = server

    response = command.perform

    assert_equal ["client1", "client2", "client3"], response
  end

end
