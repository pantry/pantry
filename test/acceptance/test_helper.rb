require 'minitest/autorun'
require 'support/matchers'
require 'celluloid/test'
require 'mocha/setup'

require 'pantry'

Pantry.logger.disable!

$all_exceptions = []
Celluloid.exception_handler do |exception|
  $all_exceptions << exception
end

Minitest.after_run do
  $all_exceptions.each do |exception|
    puts exception
    puts exception.backtrace.join("\n")
    puts ""
  end
end

# Set up a Server-only echo command so we can differentiate between
# Client requests and Server requests in the acceptance tests.
class ServerEchoCommand < Pantry::Commands::Echo
end

class Minitest::Test

  # Set up a fully functional Server + 2 Client environment on the given ports
  # Make sure that the ports given are different for each test or port-conflict
  # errors will happen.
  #
  # This helper exposes @server, @client1, and @client2 for use in tests
  def set_up_environment(pub_sub_port: 10101, receive_port: 10102, heartbeat: 300)
    Celluloid.boot

    Pantry.config.server_host  = "127.0.0.1"
    Pantry.config.pub_sub_port = pub_sub_port
    Pantry.config.receive_port = receive_port
    Pantry.config.client_heartbeat_interval = heartbeat
    Pantry.config.data_dir = File.expand_path("../../data_dir", __FILE__)

    begin
      Pantry.add_server_command(ServerEchoCommand)
    rescue Pantry::DuplicateCommandError
      # Already registered
    end

    @server = Pantry::Server.new
    @server.identity = "Test Server"
    @server.run

    @client1 = Pantry::Client.new identity: "client1", application: "pantry", environment: "test", roles: ["app1"]
    @client1.run

    @client2 = Pantry::Client.new identity: "client2", application: "pantry", environment: "test", roles: ["app2"]
    @client2.run
  end

  def teardown
    @client1.shutdown if @client1
    @client2.shutdown if @client2
    @server.shutdown  if @server
  end

end
