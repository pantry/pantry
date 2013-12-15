require 'unit/test_helper'

describe Pantry::Communication::ReceiveFile do

  class FakeReceiveNetwork
    attr_accessor :published
    def initialize
      @published = []
    end
    def publish_message(message)
      @published << message
    end
  end

  let(:networking) { FakeReceiveNetwork.new }
  let(:save_path)  { File.join(Pantry.config.data_dir, "uploaded_file") }

  let(:receiver) do
    Pantry::Communication::ReceiveFile.new(
      networking,
      save_path,
      5_000_000,
      "abc123"
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
    actor = Pantry::Communication::ReceiveFile.new(nil, save_path, 100, "abc123")
    assert_equal 36, actor.uuid.length
  end

  it "waits for a start message from the sender then sends initial chunk requests" do
    receiver.receive_message(start_message)

    pipeline_size = receiver.pipeline_size
    chunk_size    = receiver.chunk_size

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
    assert_equal ["FETCH", receiver.chunk_size * 10, receiver.chunk_size],
      networking.published[0].body
  end

  it "doesn't add to the pipeline when the last chunk has been requested" do
    sized_receiver = Pantry::Communication::ReceiveFile.new(networking, save_path, 500_000, "abc123")

    sized_receiver.receive_message(start_message)

    # Default CHUNK_SIZE of 250,000
    assert_equal 2, networking.published.length
  end

  it "writes out received chunks to the given save file path" do
    real_receiver = Pantry::Communication::ReceiveFile.new(
      networking, save_path, 11, "9cb63cb779e8c571db3199b783a36cc43cd9e7c076beeb496c39e9cc06196dc5")

    real_receiver.receive_message(start_message)
    real_receiver.receive_message(chunk_message)

    assert_equal "binary data", File.read(save_path)
  end

  it "is finished when it's received all expected file chunks" do
    sized_receiver = Pantry::Communication::ReceiveFile.new(networking, save_path, 500_000, "abc123")
    sized_receiver.receive_message(start_message)

    assert_false sized_receiver.finished?, "Receiver should not be finished, no chunks received"

    sized_receiver.receive_message(chunk_message)
    sized_receiver.receive_message(chunk_message)

    assert sized_receiver.finished?, "Receiver was not finished after receiving all chunks"
  end

  it "sends the finished message to the client when the file upload is successful" do
    real_receiver = Pantry::Communication::ReceiveFile.new(
      networking, save_path, 11, "9cb63cb779e8c571db3199b783a36cc43cd9e7c076beeb496c39e9cc06196dc5")
    real_receiver.receive_message(start_message)
    networking.published = []

    real_receiver.receive_message(chunk_message)

    success_message = networking.published[0]
    assert_equal "FINISH", success_message.body[0]
  end

  it "fails and deletes the file if the checksum does not match after upload complete" do
    real_receiver = Pantry::Communication::ReceiveFile.new(
      networking, save_path, 11, "invalid_checksum")

    real_receiver.receive_message(start_message)
    networking.published = []

    real_receiver.receive_message(chunk_message)

    assert_false File.exists?(save_path)

    error_message = networking.published[0]
    assert_not_nil error_message
    assert_equal "ERROR", error_message.body[0]
    assert_equal "Checksum did not match the uploaded file", error_message.body[1]
  end

  it "supports receiving file data chunks out-of-order" do
    real_receiver = Pantry::Communication::ReceiveFile.new(
      networking, save_path, 13, "c30facc0146cfaf7e64fea5399ccb2707a060c2d739218a1f3b20b15b8d6e89d",
      chunk_size: 5)

    real_receiver.receive_message(start_message)
    networking.published = []

    chunk1 = Pantry::Message.new
    chunk1.from = "client1"
    chunk1[:chunk_offset] = 0
    chunk1[:chunk_size] = 5
    chunk1 << "CHUNK"
    chunk1 << "Hello"

    chunk2 = Pantry::Message.new
    chunk2.from = "client1"
    chunk2[:chunk_offset] = 5
    chunk2[:chunk_size] = 5
    chunk2 << "CHUNK"
    chunk2 << " Pant"

    chunk3 = Pantry::Message.new
    chunk3.from = "client1"
    chunk3[:chunk_offset] = 10
    chunk3[:chunk_size] = 3
    chunk3 << "CHUNK"
    chunk3 << "ry!"

    real_receiver.receive_message(chunk2)
    real_receiver.receive_message(chunk3)
    real_receiver.receive_message(chunk1)

    success_message = networking.published[0]
    assert_equal "FINISH", success_message.body[0]

    assert File.exists?(save_path), "File was baleted"
    assert_equal "Hello Pantry!", File.read(save_path)
  end

end
