require 'unit/test_helper'
require 'pantry/client'
require 'pantry/communication/message'

describe Pantry::Communication::Message do

  it "takes a message type in constructor" do
    message = Pantry::Communication::Message.new("message_type")
    assert_equal "message_type", message.type
  end

  it "knows what stream it came across on" do
    message = Pantry::Communication::Message.new("")
    message.stream = "stream"
    assert_equal "stream", message.stream
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

  it "can be given the source of the sending party" do
    message = Pantry::Communication::Message.new("type")
    message.source = "server1"

    assert_equal "server1", message.source
  end

  it "can pull the identity string from an object that responds to identity" do
    message = Pantry::Communication::Message.new("type")
    client = Pantry::Client.new identity: "johnsonville"
    message.source = client

    assert_equal "johnsonville", message.source
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
    message.requires_response!

    response = message.build_response

    assert_equal "type", response.type
    assert_equal [], response.body
    assert_false response.requires_response?, "Message shouldn't require a response"
  end

  it "has a hash of metadata" do
    message = Pantry::Communication::Message.new
    message.type = "read_stuff"
    message.requires_response!
    message.source = "99 Luftballoons"

    assert_equal "read_stuff", message.metadata[:type]
    assert_equal "99 Luftballoons", message.metadata[:source]
    assert message.metadata[:requires_response]
  end

  it "takes a hash of metadata and parses out approriate values" do
    message = Pantry::Communication::Message.new
    message.metadata = {
      type: "read_stuff",
      requires_response: true,
      source: "99 Luftballoons"
    }

    assert_equal "read_stuff", message.type
    assert_equal "99 Luftballoons", message.source
    assert       message.requires_response?
  end

  it "can take a set of filters and adds them to the metadata" do
    filter = Pantry::Communication::ClientFilter.new(application: "pantry")
    message = Pantry::Communication::Message.new
    message.filter = filter

    assert_equal filter, message.filter

    message = Pantry::Communication::Message.new
    message.metadata = { :filter => { application: "pantry" } }

    assert_equal "pantry", message.filter.application
  end

end
