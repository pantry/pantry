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

  let(:networking) do
    FakeNetwork.new
  end

  let(:receiver) do
    Pantry::Communication::ReceiveFile.new(
      networking,
      "/path", 100, "abc123"
    )
  end

  it "generates a UUID to be used in all messages for this actor" do
    actor = Pantry::Communication::ReceiveFile.new(nil, "/path", 100, "abc123")
    assert_equal 36, actor.uuid.length
  end

  it "waits for a start message from the sender then sends initial chunk requests" do
    message = Pantry::Message.new
    message << "START"

    receiver.receive_message(message)

    pipeline_size = Pantry::Communication::ReceiveFile::PIPELINE_SIZE
    chunk_size    = Pantry::Communication::ReceiveFile::CHUNK_SIZE

    assert_equal pipeline_size, networking.published.length

    assert_equal ["FETCH", 0,              chunk_size], networking.published[0].body
    assert_equal ["FETCH", chunk_size,     chunk_size], networking.published[1].body
    assert_equal ["FETCH", chunk_size * 2, chunk_size], networking.published[2].body
  end

  it "ensures UUID is the same for all messages sent" do
    message = Pantry::Message.new
    message << "START"

    receiver.receive_message(message)

    networking.published.each do |msg|
      assert_equal receiver.uuid, msg.uuid
    end
  end

  it "picks up the client sending the files and ensures all messages are meant for that client" do
    message = Pantry::Message.new
    message.from = "client1"
    message << "START"

    receiver.receive_message(message)

    networking.published.each do |msg|
      assert_equal "client1", msg.to
    end
  end

  it "asks for file chunks from the sender"

  it "keeps a certain number of chunk requests in the pipeline"

  it "is finished when it's received all expected file chunks"

  it "writes out received chunks to the given save file path"

end
