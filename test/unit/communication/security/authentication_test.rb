require 'unit/test_helper'

describe Pantry::Communication::Security::Authentication do

  break unless Pantry::Communication::Security.curve_supported?

  let(:key_store) { Pantry::Communication::Security::CurveKeyStore.new("server_keys") }
  let(:auth) { Pantry::Communication::Security::Authentication.new(key_store) }

  class BogusZapSocket
    def initialize(client_key: nil, mechanism: "CURVE")
      @client_key = client_key
      @mechanism = mechanism
    end

    def read
      @buffer ||= [
        "1.0",
        "1",
        "domain",
        "127.0.0.1",
        "identity",
        @mechanism,
        @client_key
      ]
      @buffer.shift
    end

    def more_parts?
      @buffer.length > 0
    end

    attr_reader :message
    def write(message)
      @message = message
    end
  end

  def assert_response_valid(response)
    assert_equal 6, response.length, "Response message wasn't long enough"
    assert_equal "1.0", response[0], "Invalid version code"
    assert_equal "1", response[1], "Invalid sequence in response"
    assert_equal "", response[4] # username
    assert_equal "", response[5] # metadata
  end

  def assert_authorized(response)
    assert_response_valid(response)
    assert_equal "200", response[2], "Invalid response code"
    assert_equal "OK", response[3], "Invalid response message"
  end

  def assert_not_authorized(response, expected_message)
    assert_response_valid(response)
    assert_equal "400", response[2], "Invalid response code"
    assert_equal expected_message, response[3], "Invalid response message"
  end

  it "authenticates a client with a known client public key" do
    key_store.expects(:known_client?).with("client_key").returns(true)
    zmq_socket = BogusZapSocket.new(client_key: "client_key")

    auth.instance_variable_set("@socket", zmq_socket)
    auth.process_next_request

    assert_authorized(zmq_socket.message)
  end

  it "rejects a client with an unknown public key" do
    key_store.expects(:known_client?).with("client_key").returns(false)
    zmq_socket = BogusZapSocket.new(client_key: "client_key")

    auth.instance_variable_set("@socket", zmq_socket)
    auth.process_next_request

    assert_not_authorized(zmq_socket.message, "Unknown Client")
  end

  it "rejects auth attempts for PLAIN security" do
    zmq_socket = BogusZapSocket.new(client_key: "client_key", mechanism: "PLAIN")

    auth.instance_variable_set("@socket", zmq_socket)
    auth.process_next_request

    assert_not_authorized(zmq_socket.message, "Invalid Mechanism")
  end

  it "rejects auth attempts for NULL security" do
    zmq_socket = BogusZapSocket.new(client_key: "client_key", mechanism: "NULL")

    auth.instance_variable_set("@socket", zmq_socket)
    auth.process_next_request

    assert_not_authorized(zmq_socket.message, "Invalid Mechanism")
  end

  it "allows a client in if there are no known Clients yet"

end
