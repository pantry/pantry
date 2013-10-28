require 'minitest/autorun'
require 'support/matchers'

require 'pantry'

class Minitest::Test

  # We are dealing with actual socket communication here, so we want
  # to set up the socket communication itself once then play with various
  # ways we communicate over these sockets.
  def self.setup_environment
    if $basic_server_client_comm_setup.nil?
      Celluloid.boot

      Pantry.config.server_host  = "127.0.0.1"
      Pantry.config.pub_sub_port = 10101
      Pantry.config.receive_port = 10102

      $server = Pantry::Server.new
      $server.run

      $client1 = Pantry::Client.new identity: "client1", application: "pantry"
      $client1.run

      $client2 = Pantry::Client.new identity: "client2", application: "pantry"
      $client2.run

      # Ensure communication figures itself out in time
      sleep 1

      Minitest.after_run do
        $client1.shutdown
        $client2.shutdown
        $server.shutdown
      end

      $basic_server_client_comm_setup = true
    end

    [$server, $client1, $client2]
  end

end
