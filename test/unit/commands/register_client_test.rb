require 'unit/test_helper'
require 'pantry/server'
require 'pantry/commands/register_client'

describe Pantry::Commands::RegisterClient do

  it "builds a client and notifies server of the new client" do
    message = Pantry::Communication::Message.new("RegisterClient")
    message.source = "client 427"
    message << {
      :environment => "test", :application => "pantry", :roles => %w(app db)
    }.to_json

    server = Pantry::Server.new

    command = Pantry::Commands::RegisterClient.from_message(message)
    command.server_or_client = server
    command.perform

    assert_equal 1, server.clients.length
    assert_equal "client 427", server.clients[0].identity
    assert_equal "pantry", server.clients[0].application
    assert_equal "test", server.clients[0].environment
    assert_equal %w(app db), server.clients[0].roles
  end

  it "builds message including the Client's information for registration" do
    command = Pantry::Commands::RegisterClient.new(Pantry::Client.new(
      identity: "Test123", application: "pantry", environment: "test",
      roles: %w(app db)
    ))

    message = command.to_message

    assert_equal(
      {:application => "pantry", :environment => "test", :roles => %w(app db)}.to_json,
      message.body[0]
    )
  end

end
