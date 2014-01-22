require 'acceptance/test_helper'

describe "ZMQ4 CURVE security" do

  break unless Pantry::Communication::Security.curve_supported?

  let(:key_dir) {
    Pantry.root.join("security", "curve").tap do |dir|
      FileUtils.mkdir_p dir
    end
  }

  def set_up_encrypted(ports_start_at)
    Celluloid.boot
    configure_pantry(ports_start_at: ports_start_at, security: "curve")

    server_public, server_private = ZMQ::Util.curve_keypair

    File.open(key_dir.join("server.pub"), "w+") do |file|
      file.write(server_public)
    end

    File.open(key_dir.join("server_keys.yml"), "w+") do |f|
      f.write(YAML.dump({
        "private_key" => server_private, "public_key" => server_public}))
    end
  end

  it "configures CURVE security for encrypted server/client communication" do
    set_up_encrypted(15000)

    server = Pantry::Server.new
    server.identity = "Encrypted Server"
    server.run

    client = Pantry::Client.new identity: "encrypted-client"
    client.run

    message = ServerEchoCommand.new("Hello Server").to_message
    response_future = client.send_request(message)

    assert_equal ["Hello Server"], response_future.value(2).body
  end

  it "rejects clients who connect with the wrong server key" do
    set_up_encrypted(15010)

    # Write out a bad server public key so the client can't authenticate
    FileUtils.rm key_dir.join("server.pub")
    File.open(key_dir.join("server.pub"), "w+") do |file|
      file.write("invalid security token1234567890")
    end

    server = Pantry::Server.new
    server.identity = "Encrypted Server"
    server.run

    client = Pantry::Client.new identity: "encrypted-client"
    client.run

    message = ServerEchoCommand.new("Hello Server").to_message
    response_future = client.send_request(message)

    assert_raises(Celluloid::TimeoutError) do
      response_future.value(1).body
    end
  end

end
