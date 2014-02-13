require 'unit/test_helper'

describe Pantry::Communication::Security::CurveSecurity do

  break unless Pantry::Communication::Security.curve_supported?

  fake_fs!

  describe "Client" do

    it "configures the client with the stored server's public key and client keys" do
      client = Pantry::Communication::Security::CurveSecurity.client

      curve_dir = Pantry.root.join("security", "curve")
      client_keys = YAML.load_file(curve_dir.join("client_keys.yml"))

      socket = mock
      socket.expects(:set).with(::ZMQ::CURVE_SERVERKEY, client_keys["server_public_key"])
      socket.expects(:set).with(::ZMQ::CURVE_PUBLICKEY, client_keys["public_key"])
      socket.expects(:set).with(::ZMQ::CURVE_SECRETKEY, client_keys["private_key"])

      client.configure_socket(socket)
    end

  end

  describe "Server" do

    it "configures the socket with the stored server private key" do
      server = Pantry::Communication::Security::CurveSecurity.server

      curve_dir = Pantry.root.join("security", "curve")
      server_keys = YAML.load_file(curve_dir.join("server_keys.yml"))

      socket = mock
      socket.expects(:set).with(::ZMQ::CURVE_SERVER, 1)
      socket.expects(:set).with(::ZMQ::CURVE_SECRETKEY, server_keys["private_key"])

      server.configure_socket(socket)
    end

  end

end
