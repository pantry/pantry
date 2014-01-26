require 'support/minitest'
require 'support/matchers'
require 'celluloid/test'
require 'mocha/setup'
require 'fakefs/safe'

require 'pantry'

Pantry.logger.disable!
#Pantry.config.log_level = :debug

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

class SaveInfoProgressListener < Pantry::CLIProgressListener

  attr_accessor :said

  def initialize
    @said = []
    super
  end

  def say(message)
    @said << message
  end

end

class Minitest::Test

  def setup
    Pantry.config.ignore_dot_pantry = true
  end

  # Set up a fully functional Server + 2 Client environment on the given ports
  # Make sure that the ports given are different for each test or port-conflict
  # errors will happen. Make sure each test has a wide enough range between
  # port_start_at values (10 is a good number)
  #
  # This helper exposes @server, @client1, and @client2 for use in tests
  def set_up_environment(ports_start_at: 10101, heartbeat: 300, security: nil)
    Celluloid.boot

    configure_pantry(ports_start_at: ports_start_at, heartbeat: heartbeat, security: security)

    @server = Pantry::Server.new
    @server.identity = "Test Server"
    @server.run

    @client1 = Pantry::Client.new identity: "client1", application: "pantry", environment: "test", roles: ["app1"]
    @client1.run

    @client2 = Pantry::Client.new identity: "client2", application: "pantry", environment: "test", roles: ["app2"]
    @client2.run
  end

  def configure_pantry(ports_start_at: 10101, heartbeat: 300, security: nil)
    Pantry.config.server_host  = "127.0.0.1"
    Pantry.config.pub_sub_port = ports_start_at
    Pantry.config.receive_port = ports_start_at + 1
    Pantry.config.file_service_port = ports_start_at + 2
    Pantry.config.client_heartbeat_interval = heartbeat
    Pantry.config.data_dir = File.expand_path("../../data_dir", __FILE__)
    Pantry.config.response_timeout = 5
    Pantry.config.security = security

    begin
      Pantry.add_server_command(ServerEchoCommand)
    rescue Pantry::DuplicateCommandError
      # Already registered
    end
  end

  def teardown
    @client1.shutdown if @client1
    @client2.shutdown if @client2
    @server.shutdown  if @server

    clean_up_pantry_root
  end

end
