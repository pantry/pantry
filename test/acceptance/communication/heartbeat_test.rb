require 'acceptance/test_helper'

describe "Client / Server heartbeats" do

  before do
    @server, @client1, @client2 = self.class.setup_environment
  end

  describe "Client" do
    it "re-registers with the server every interval seconds" do
      # Clean out the server registry then wait for clients to re-register themselves
      @server.client_registry.clear!

      sleep 2

      assert @server.client_registry.include?(@client1), "Client1 did not check in again"
      assert @server.client_registry.include?(@client2), "Client2 did not check in again"
    end
  end

end
