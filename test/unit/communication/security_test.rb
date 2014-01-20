require 'unit/test_helper'

describe Pantry::Communication::Security do

  describe ".new_client" do
    it "returns the Client side of the configured security model" do
      config = Pantry::Config.new
      config.security = nil

      client_handler = Pantry::Communication::Security.new_client(config)

      assert_not_nil client_handler
      assert client_handler.is_a?(Pantry::Communication::Security::NullSecurity),
        "Returned the wrong kind of client handler"
    end

    it "raises if given security type is unknown" do
      config = Pantry::Config.new
      config.security = "--unknown--"

      assert_raises(Pantry::Communication::Security::UnknownSecurityStrategyError) do
        Pantry::Communication::Security.new_client(config)
      end
    end
  end

  describe ".new_server" do
    it "returns the Server side of the configured security model" do
      config = Pantry::Config.new
      config.security = nil

      server_handler = Pantry::Communication::Security.new_server(config)

      assert_not_nil server_handler
      assert server_handler.is_a?(Pantry::Communication::Security::NullSecurity),
        "Returned the wrong kind of server handler"
    end

    it "raises if given security type is unknown" do
      config = Pantry::Config.new
      config.security = "--unknown--"

      assert_raises(Pantry::Communication::Security::UnknownSecurityStrategyError) do
        Pantry::Communication::Security.new_server(config)
      end
    end
  end

end
