require 'acceptance/test_helper'

describe "CLI asks for command line execution on clients" do

  before do
    @server, @client1, @client2 = self.class.setup_environment
  end

#  it "asks clients to run and return output of a built-in command" do
#    cli = Pantry::CLI.new
#    future = cli.request("execute", "hostname")
#
#    responses = Timeout::timeout(2) { future.value }
#
#    assert_equal 2, response.length
#
#    client1_response = response.select {|m| m.identity == @client1.identity }
#    client2_response = response.select {|m| m.identity == @client2.identity }
#
#    assert_equal [`hostname`, "", "0"], client1_response.body
#    assert_equal [`hostname`, "", "0"], client2_response.body
#  end
#
#  it "asks clients to run and return output of a custom command" do
#    @client1.on(:custom_command) do |message|
#      "Client 1 Custom Response"
#    end
#
#    @client2.on(:custom_command) do |message|
#      "Client 2 Custom Response"
#    end
#
#    cli = Pantry::CLI.new Pantry.config.server_host, Pantry.config.cli_port
#    future = cli.request("execute", "hostname")
#
#    responses = Timeout::timeout(2) { future.value }
#
#    assert_equal 2, response.length
#
#    client1_response = response.select {|m| m.identity == @client1.identity }
#    client2_response = response.select {|m| m.identity == @client2.identity }
#
#    assert_equal ["Client 1 Custom Response"], client1_response.body
#    assert_equal ["Client 2 Custom Response"], client2_response.body
#  end
#
#  it "asks for a subset of clients"
#
end
