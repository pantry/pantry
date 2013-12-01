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

      body = JSON.parse(zmq_message[2])
      assert_equal "value", body["key"]
    end

    it "converts arrays in the body to JSON" do
      pantry_message << ["some", "values", 1, 2, true]

      zmq_message = Pantry::Communication::SerializeMessage.to_zeromq(pantry_message)

      body = JSON.parse(zmq_message[2])
      assert_equal ["some", "values", 1, 2, true], body
    end

  end

end
