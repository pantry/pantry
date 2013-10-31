require 'acceptance/test_helper'

describe "Server requesting a command line execution on clients" do

  before do
    @server, @client1, @client2 = self.class.setup_environment
  end

  it "asks a client for the output (stdout, stderr, and status) of a given command" do
    message = Pantry::Commands::ExecuteShell.new("hostname").to_message

    future = @server.send_request(@client1, message)

    assert_equal [`hostname`, "", "0"], future.value(1).body
  end

end
