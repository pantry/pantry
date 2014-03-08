require 'unit/test_helper'

describe Pantry::Message do

  it "takes a message type in constructor" do
    message = Pantry::Message.new("message_type")
    assert_equal "message_type", message.type
  end

  it "generates a UUID on construction" do
    message = Pantry::Message.new("message_type")
    assert_not_nil message.uuid
    assert message.uuid.length > 10
  end

  it "knows who the message is meant for" do
    message = Pantry::Message.new("")
    message.to = "stream"
    assert_equal "stream", message.to
  end

  it "defaults the #to value to all (the empty string)" do
    message = Pantry::Message.new("")
    assert_equal "", message.to
  end

  it "can be given strings for the body parts" do
    message = Pantry::Message.new("type")
    message << "Part 1"
    message << "Part 2"

    assert_equal ["Part 1", "Part 2"], message.body
  end

  it "can be given the identity of the sending party" do
    message = Pantry::Message.new("type")
    message.from = "server1"

    assert_equal "server1", message.from
  end

  it "can pull the identity string from an object that responds to identity" do
    message = Pantry::Message.new("type")
    client = Pantry::Client.new identity: "johnsonville"
    message.from = client

    assert_equal "johnsonville", message.from
  end

  it "can be flagged to require a response" do
    message = Pantry::Message.new("type")
    message.requires_response!

    assert message.requires_response?
  end

  it "can build a response version of itself" do
    message = Pantry::Message.new("type")
    message << "Body part 1"
    message << "Body part 2"
    message.to = "server"
    message.from = "client"
    message.forwarded!
    message.requires_response!

    response = message.build_response

    assert_equal "type", response.type
    assert_equal [], response.body
    assert_false response.requires_response?, "Message shouldn't require a response"
    assert_equal "client", response.to
    assert_equal "server", response.from
    assert response.forwarded?

    assert_equal message.uuid, response.uuid
  end

  it "clones custom metadata in a response message" do
    message = Pantry::Message.new("type")
    message[:custom_data] = "one"

    response = message.build_response

    assert_equal "one", response[:custom_data]

    response[:custom_data] = "two"
    assert_equal "one", message[:custom_data]
    assert_equal "two", response[:custom_data]
  end

  it "can be flagged as being forwarded" do
    message = Pantry::Message.new("type")
    assert_false message.forwarded?

    message.forwarded!
    assert message.forwarded?
  end

  it "has a hash of metadata" do
    message = Pantry::Message.new
    message.type = "read_stuff"
    message.requires_response!
    message.forwarded!
    message.from = "99 Luftballoons"
    message.to = "streamer"

    assert_not_nil message.metadata[:uuid]
    assert_equal "read_stuff", message.metadata[:type]
    assert_equal "99 Luftballoons", message.metadata[:from]
    assert_equal "streamer", message.metadata[:to]
    assert message.metadata[:requires_response]
    assert message.metadata[:forwarded]
  end

  it "ensures the #to field is always a string when writing metadata" do
    message = Pantry::Message.new
    assert_equal "", message.metadata[:to]
  end

  it "knows if it came from the server or a client" do
    message = Pantry::Message.new
    message.from = Pantry::SERVER_IDENTITY

    assert message.from_server?
  end

  it "takes a hash of metadata and parses out approriate values" do
    message = Pantry::Message.new
    message.metadata = {
      type: "read_stuff",
      requires_response: true,
      forwarded: true,
      from: "99 Luftballoons",
      to: "streamer",
      uuid: "123-4567-890-1234"
    }

    assert_equal "123-4567-890-1234", message.uuid
    assert_equal "read_stuff", message.type
    assert_equal "99 Luftballoons", message.from
    assert_equal "streamer", message.to
    assert       message.requires_response?
    assert       message.forwarded?
  end

  it "ensures the #to field is always a string when reading metadata" do
    message = Pantry::Message.new
    message.metadata = {
      to: nil,
    }
    assert_equal "", message.to
  end

  it "allows custom metadata entries" do
    message = Pantry::Message.new
    message[:metadata_1] = "my metadata"
    message[:some_name] = "johnson"

    assert_equal "my metadata", message[:metadata_1]
    assert_equal "johnson", message[:some_name]

    assert_equal "my metadata", message.metadata[:custom][:metadata_1]
    assert_equal "johnson", message.metadata[:custom][:some_name]
  end

  it "loads unknown metadata keys into the custom metadata" do
    message = Pantry::Message.new
    message.metadata = {
      custom: {
        metadata_1: "my metadata",
        some_name:  "johnson"
      }
    }

    assert_equal "my metadata", message[:metadata_1]
    assert_equal "johnson", message[:some_name]
  end

end
