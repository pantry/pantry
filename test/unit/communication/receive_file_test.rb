require 'unit/test_helper'

describe Pantry::Communication::ReceiveFile do

  class FakeNetwork
    attr_accessor :published
    def initialize
      @published = []
    end
    def publish_message(message)
      @published << message
    end
  end

  let(:chunk_size) { Pantry::Communication::ReceiveFile::CHUNK_SIZE }

  let(:networking) { FakeNetwork.new }

  let(:receiver) do
    Pantry::Communication::ReceiveFile.new(
      networking,
      "/path", 5_000_000, "abc123"
    )
  end

  let(:start_message) do
    Pantry::Message.new.tap do |msg|
      msg.from = "client1"
      msg << "START"
    end
  end

  let(:chunk_message) do
    Pantry::Message.new.tap do |msg|
      msg.from = "client1"
      msg[:chunk_offset] = 0
      msg[:chunk_size] = 1_000
      msg << "CHUNK"
      msg << "binary data"
    end
  end

  it "generates a UUID to be used in all messages for this actor" do
    actor = Pantry::Communication::ReceiveFile.new(nil, "/path", 100, "abc123")
    assert_equal 36, actor.uuid.length
  end

  it "waits for a start message from the sender then sends initial chunk requests" do
    receiver.receive_message(start_message)

    pipeline_size = Pantry::Communication::ReceiveFile::PIPELINE_SIZE

    assert_equal pipeline_size, networking.published.length

    assert_equal ["FETCH", 0,              chunk_size], networking.published[0].body
    assert_equal ["FETCH", chunk_size,     chunk_size], networking.published[1].body
    assert_equal ["FETCH", chunk_size * 2, chunk_size], networking.published[2].body
  end

  it "ensures UUID is the same for all messages sent" do
    receiver.receive_message(start_message)

    networking.published.each do |msg|
      assert_equal receiver.uuid, msg.uuid
    end
  end

  it "picks up the client sending the files and ensures all messages are meant for that client" do
    receiver.receive_message(start_message)

    networking.published.each do |msg|
      assert_equal "client1", msg.to
    end
  end

  it "keeps a certain number of chunk requests in the pipeline" do
    receiver.receive_message(start_message)
    networking.published = []

    receiver.receive_message(chunk_message)

    # We've already requested 10 chunks. Having received one chunk we request the 11th (0-based)
    assert_equal 1, networking.published.length
    assert_equal ["FETCH", chunk_size * 10, chunk_size], networking.published[0].body
  end

  it "doesn't add to the pipeline when the last chunk has been requested" do
    sized_receiver = Pantry::Communication::ReceiveFile.new(networking, "/path", 500_000, "abc123")

    sized_receiver.receive_message(start_message)

    # Assuming CHUNK_SIZE of 250,000
    assert_equal 2, networking.published.length
  end

  it "is finished when it's received all expected file chunks" do
    sized_receiver = Pantry::Communication::ReceiveFile.new(networking, "/path", 500_000, "abc123")
    sized_receiver.receive_message(start_message)

    assert_false sized_receiver.finished?, "Receiver should not be finished, no chunks received"

    sized_receiver.receive_message(chunk_message)
    sized_receiver.receive_message(chunk_message)

    assert sized_receiver.finished?, "Receiver was not finished after receiving all chunks"
  end

  it "writes out received chunks to the given save file path"

  it "supports receiving file data chunks out-of-order"

  it "drops file system chunks if received before a START message?"

end
