require 'unit/test_helper'

describe Pantry::Commands::RegisterClient do

  it "builds a client and notifies server of the new client" do
    message = Pantry::Message.new("RegisterClient")
    message.from = "client 427"
    message << {
      :environment => "test", :application => "pantry", :roles => %w(app db)
    }

    server = Pantry::Server.new

    command = Pantry::Commands::RegisterClient.from_message(message)
    command.server_or_client = server
    command.perform

    clients = server.client_registry.all

    assert_equal 1, clients.length
    assert_equal "client 427", clients[0].identity
    assert_equal "pantry", clients[0].application
    assert_equal "test", clients[0].environment
    assert_equal %w(app db), clients[0].roles
  end

  it "builds message including the Client's information for registration" do
    command = Pantry::Commands::RegisterClient.new(Pantry::Client.new(
      identity: "Test123", application: "pantry", environment: "test",
      roles: %w(app db)
    ))

    message = command.to_message

    assert_equal(
      {:application => "pantry", :environment => "test", :roles => %w(app db)},
      message.body[0]
    )
  end

end
