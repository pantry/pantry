require 'unit/test_helper'

describe Pantry::Communication::SerializeMessage do

  describe ".to_zeromq" do

    let(:pantry_message) do
      message = Pantry::Message.new
      message.to = "to"
      message.from = "from"
      message
    end

    it "builds a list of message parts containing to, metadata, and body" do
      pantry_message << "Test Body"

      zmq_message = Pantry::Communication::SerializeMessage.to_zeromq(pantry_message)

      assert_equal 3, zmq_message.length
      assert_equal "to", zmq_message[0]
      assert_equal "Test Body", zmq_message[2]
    end

    it "ensures `to` is always a string" do
      pantry_message.to = nil
      zmq_message = Pantry::Communication::SerializeMessage.to_zeromq(pantry_message)

      assert_equal "", zmq_message[0]
    end

    it "serializes the metadata as JSON" do
      zmq_message = Pantry::Communication::SerializeMessage.to_zeromq(pantry_message)

      metadata = JSON.parse(zmq_message[1])

      assert_equal "to", metadata["to"]
      assert_equal "from", metadata["from"]
    end

    it "ensures all parts of the body are strings" do
      pantry_message << 1
      pantry_message << 2

      zmq_message = Pantry::Communication::SerializeMessage.to_zeromq(pantry_message)

      assert_equal "1", zmq_message[2]
      assert_equal "2", zmq_message[3]
    end

    it "turns nil entries into strings" do
      pantry_message << nil
      pantry_message << "this"

      zmq_message = Pantry::Communication::SerializeMessage.to_zeromq(pantry_message)

      assert_equal "", zmq_message[2]
      assert_equal "this", zmq_message[3]
    end

    it "converts hashes in the body to JSON" do
      pantry_message << {:key => "value"}

      zmq_message = Pantry::Communication::SerializeMessage.to_zeromq(pantry_message)

      body = JSON.parse(zmq_message[2][1..-1])
      assert_equal "value", body["key"]
    end

    it "converts arrays in the body to JSON" do
      pantry_message << ["some", "values", 1, 2, true]

      zmq_message = Pantry::Communication::SerializeMessage.to_zeromq(pantry_message)

      body = JSON.parse(zmq_message[2][1..-1])
      assert_equal ["some", "values", 1, 2, true], body
    end

  end

  describe ".from_zeromq" do

    let(:is_json) { Pantry::Communication::SerializeMessage::IS_JSON }

    it "takes an array and builds a Message from the parts" do
      parts = [ "source", {}.to_json, "body1" ]

      message = Pantry::Communication::SerializeMessage.from_zeromq(parts)

      assert_equal "source", message.to
      assert_equal ["body1"], message.body
    end

    it "parses out JSON into a Hash" do
      parts = [ "source", {:type => "command"}.to_json, "body1" ]

      message = Pantry::Communication::SerializeMessage.from_zeromq(parts)

      assert_equal "command", message.type
    end

    it "handles JSON based body entries" do
      parts = [ "source", {}.to_json, is_json + {:key => "value"}.to_json ]

      message = Pantry::Communication::SerializeMessage.from_zeromq(parts)

      assert_equal "value", message.body[0][:key]
    end

    it "handles Array based body entries" do
      parts = [ "source", {}.to_json, is_json + [1, 2, 3, "go"].to_json ]

      message = Pantry::Communication::SerializeMessage.from_zeromq(parts)

      assert_equal [1, 2, 3, "go"], message.body[0]
    end

    it "returns raw parts if they don't parse as JSON" do
      parts = [ "source", {}.to_json, "{ blah blah thing", "[notreallyanarray" ]

      message = Pantry::Communication::SerializeMessage.from_zeromq(parts)

      assert_equal "{ blah blah thing", message.body[0]
      assert_equal "[notreallyanarray", message.body[1]
    end

  end

end
