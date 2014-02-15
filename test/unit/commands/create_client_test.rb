require 'unit/test_helper'

describe Pantry::Commands::CreateClient do

  mock_ui!

  it "asks server for a new set of encryption keys" do
    server = Pantry::Server.new

    command = Pantry::Commands::CreateClient.new
    command.server = server
    server.expects(:create_client).returns(
      server_public_key: "server public key",
      public_key:  "client public",
      private_key: "client private"
    )

    keys = command.perform(Pantry::Message.new)

    assert_equal "server public key", keys[:server_public_key]
    assert_equal "client public", keys[:public_key]
    assert_equal "client private", keys[:private_key]
  end

end
