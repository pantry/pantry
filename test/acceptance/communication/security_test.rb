require 'acceptance/test_helper'

describe "ZMQ4 CURVE security" do

  break unless Pantry::Communication::Security.curve_supported?

  def set_up_encrypted(ports_start_at, options = {})
    Celluloid.boot
    configure_pantry(ports_start_at: ports_start_at, security: "curve")

    server_public, server_private = ZMQ::Util.curve_keypair
    client_public, client_private = ZMQ::Util.curve_keypair

    known_clients = options[:known_clients] || [client_public]

    key_dir = Pantry.root.join("security", "curve")
    FileUtils.mkdir_p(key_dir)

    File.open(key_dir.join("server_keys.yml"), "w+") do |f|
      f.write(YAML.dump({
        "private_key" => server_private,
        "public_key" => options[:server_public_key] || server_public,
        "client_keys" => known_clients
      }))
    end

    File.open(key_dir.join("client_keys.yml"), "w+") do |f|
      f.write(YAML.dump({
        "private_key" => client_private, "public_key" => client_public,
        "server_public_key" => options[:server_public_key] || server_public
      }))
    end
  end

  describe "connectivity" do
    def assert_message_timeout(client)
      message = ServerEchoCommand.new("Hello Server").to_message
      response_future = client.send_request(message)

      assert_raises(Celluloid::TimeoutError) do
        response_future.value(1).body
      end
    end

    def assert_successful_message(client)
      message = ServerEchoCommand.new("Hello Server").to_message
      response_future = client.send_request(message)

      assert_equal ["Hello Server"], response_future.value(2).body
    end

    it "configures CURVE security for encrypted server/client communication" do
      set_up_encrypted(15000)

      server = Pantry::Server.new
      server.identity = "Encrypted Server"
      server.run

      client = Pantry::Client.new identity: "encrypted-client"
      client.run

      assert_successful_message(client)
    end

    it "rejects clients who connect with the wrong server key" do
      set_up_encrypted(15010, server_public_key: "invalid security token1234567890")

      server = Pantry::Server.new
      server.identity = "Encrypted Server"
      server.run

      client = Pantry::Client.new identity: "encrypted-client"
      client.run

      assert_message_timeout(client)
    end

    it "rejects a client whos public key is not known by the server" do
      set_up_encrypted(15020, known_clients: ["some other client here1234567890"])

      server = Pantry::Server.new
      server.identity = "Encrypted Server"
      server.run

      client = Pantry::Client.new identity: "encrypted-client"
      client.run

      assert_message_timeout(client)
    end

  end

  describe "requesting new client keys" do

    mock_ui!

    it "returns a new set of client keys as requested" do
      set_up_encrypted(15030)

      server = Pantry::Server.new
      server.identity = "Encrypted Server"
      server.run

      cli = Pantry::CLI.new(
        ["client:create"],
        identity: "encrypted-client"
      )
      cli.run

      assert_match /server_public_key/, stdout
      assert_match /public_key/, stdout
      assert_match /private_key/, stdout
    end

  end

end
