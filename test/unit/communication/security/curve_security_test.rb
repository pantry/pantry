require 'unit/test_helper'

describe Pantry::Communication::Security::CurveSecurity do

  break unless Pantry::Communication::Security.curve_supported?

  fake_fs!

  describe "Client" do

    let(:client) { Pantry::Communication::Security::CurveSecurity.client }

    it "sets up directory structure in Pantry.root for storing credentials" do
      client

      curve_dir = Pantry.root.join("security", "curve")
      assert File.directory?(curve_dir), "Storage stucture not set up"
    end

    it "generates a new set of client public/private keys if none exist" do
      client

      curve_dir = Pantry.root.join("security", "curve")
      assert File.exists?(curve_dir.join("my_keys.yml")), "Did not generate my keys"

      keys = YAML.load_file(curve_dir.join("my_keys.yml"))
      assert_not_nil keys["private_key"], "Did not generate a private key"
      assert_not_nil keys["public_key"],  "Did not generate a public key"
    end

    it "configures the client with the stored server's public key and client keys" do
      client

      curve_dir = Pantry.root.join("security", "curve")
      File.open(curve_dir.join("server.pub"), "w+") do |f|
        f.write("server public key")
      end

      client_keys = YAML.load_file(curve_dir.join("my_keys.yml"))

      socket = mock
      socket.expects(:setsockopt).with(::ZMQ::CURVE_SERVERKEY, "server public key")
      socket.expects(:setsockopt).with(::ZMQ::CURVE_PUBLICKEY, client_keys["public_key"])
      socket.expects(:setsockopt).with(::ZMQ::CURVE_SECRETKEY, client_keys["private_key"])

      client.configure_socket(socket)
    end

    it "loads and configures from client keys already written out" do
      curve_dir = Pantry.root.join("security", "curve")
      FileUtils.mkdir_p curve_dir

      File.open(curve_dir.join("server.pub"), "w+") do |f|
        f.write("server public key\n")
      end

      File.open(curve_dir.join("my_keys.yml"), "w+") do |f|
        f.write(YAML.dump({
          "private_key" => "client private key", "public_key" => "client public key"}))
      end

      socket = mock
      socket.expects(:setsockopt).with(::ZMQ::CURVE_SERVERKEY, "server public key")
      socket.expects(:setsockopt).with(::ZMQ::CURVE_PUBLICKEY, "client public key")
      socket.expects(:setsockopt).with(::ZMQ::CURVE_SECRETKEY, "client private key")

      client.configure_socket(socket)
    end

    it "errors out if no server public key found" do
      client
      socket = stub

      assert_raises(Pantry::Communication::Security::CurveSecurity::MissingServerPublicKey) do
        client.configure_socket(socket)
      end
    end

  end

  describe "Server" do

    it "sets up directory structure in Pantry.root for storing credentials"

    it "generates a new set of server public/private keys if none exist"

    it "configures the socket with the stored server private key"

    it "writes out the client's public key if new unknown client now connecting"

  end

end
