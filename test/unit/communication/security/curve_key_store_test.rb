require 'unit/test_helper'

describe Pantry::Communication::Security::CurveKeyStore do

  break unless Pantry::Communication::Security.curve_supported?

  let(:key_store) { Pantry::Communication::Security::CurveKeyStore.new("my_keys") }

  def write_test_keys(known_client_keys = nil)
    security_dir = Pantry.root.join("security", "curve")
    FileUtils.mkdir_p security_dir
    File.open(security_dir.join("my_keys.yml"), "w+") do |f|
      f.write(YAML.dump({
        "private_key" => "private key", "public_key" => "public key",
        "server_public_key" => "server key",
        "client_keys" => known_client_keys || ["client1", "client2"]
      }))
    end
  end

  it "sets up directory structure in Pantry.root for storing credentials" do
    key_store

    curve_dir = Pantry.root.join("security", "curve")
    assert File.directory?(curve_dir), "Storage stucture not set up"
  end

  it "generates a new set of server public/private keys if none exist" do
    key_store

    curve_dir = Pantry.root.join("security", "curve")
    assert File.exists?(curve_dir.join("my_keys.yml")), "Did not generate my keys"

    keys = YAML.load_file(curve_dir.join("my_keys.yml"))
    assert_not_nil keys["private_key"], "Did not generate a private key"
    assert_not_nil keys["public_key"],  "Did not generate a public key"
  end

  it "can read back the public key" do
    write_test_keys
    assert_equal "public key", key_store.public_key
  end

  it "can read back the private key" do
    write_test_keys
    assert_equal "private key", key_store.private_key
  end

  it "can read back the server public key" do
    write_test_keys
    assert_equal "server key", key_store.server_public_key
  end

  it "encodes binary client public key for checking against known list" do
    client_pub, priv = ZMQ::Util.curve_keypair
    write_test_keys([client_pub])

    decoded = FFI::MemoryPointer.from_string(' ' * 32)
    binary_pub = LibZMQ.zmq_z85_decode(decoded, client_pub)
    assert key_store.known_client?(binary_pub), "Should have matched binary with z85 encoded"
  end

end
