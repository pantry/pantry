require 'unit/test_helper'

describe Pantry::Communication::Message do

  it "takes a message type in constructor" do
    message = Pantry::Communication::Message.new("message_type")
    assert_equal "message_type", message.type
  end

  it "knows who the message is meant for" do
    message = Pantry::Communication::Message.new("")
    message.to = "stream"
    assert_equal "stream", message.to
  end

  it "can be given strings for the body parts" do
    message = Pantry::Communication::Message.new("type")
    message << "Part 1"
    message << "Part 2"

    assert_equal ["Part 1", "Part 2"], message.body
  end

  it "ensures the body is always a flattened array" do
    message = Pantry::Communication::Message.new("type")
    message << ["Part 1"]
    message << [[[[["Part 2"]]]]]

    assert_equal ["Part 1", "Part 2"], message.body
  end

  it "ensures all parts of a Message are strings" do
    message = Pantry::Communication::Message.new("type")
    message << 1
    message << 2

    assert_equal ["1", "2"], message.body
  end

  it "turns nil entries into the empty string" do
    message = Pantry::Communication::Message.new("type")
    message << 1
    message << nil
    message << 2

    assert_equal ["1", "", "2"], message.body
  end

  it "can be given the identity of the sending party" do
    message = Pantry::Communication::Message.new("type")
    message.from = "server1"

    assert_equal "server1", message.from
  end

  it "can pull the identity string from an object that responds to identity" do
    message = Pantry::Communication::Message.new("type")
    client = Pantry::Client.new identity: "johnsonville"
    message.from = client

    assert_equal "johnsonville", message.from
  end

  it "can be flagged to require a response" do
    message = Pantry::Communication::Message.new("type")
    message.requires_response!

    assert message.requires_response?
  end

  it "can build a response version of itself" do
    message = Pantry::Communication::Message.new("type")
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
  end

  it "can be flagged as being forwarded" do
    message = Pantry::Communication::Message.new("type")
    assert_false message.forwarded?

    message.forwarded!
    assert message.forwarded?
  end

  it "has a hash of metadata" do
    message = Pantry::Communication::Message.new
    message.type = "read_stuff"
    message.requires_response!
    message.forwarded!
    message.from = "99 Luftballoons"
    message.to = "streamer"

    assert_equal "read_stuff", message.metadata[:type]
    assert_equal "99 Luftballoons", message.metadata[:from]
    assert_equal "streamer", message.metadata[:to]
    assert message.metadata[:requires_response]
    assert message.metadata[:forwarded]
  end

  it "takes a hash of metadata and parses out approriate values" do
    message = Pantry::Communication::Message.new
    message.metadata = {
      type: "read_stuff",
      requires_response: true,
      forwarded: true,
      from: "99 Luftballoons",
      to: "streamer"
    }

    assert_equal "read_stuff", message.type
    assert_equal "99 Luftballoons", message.from
    assert_equal "streamer", message.to
    assert       message.requires_response?
    assert       message.forwarded?
  end

end
