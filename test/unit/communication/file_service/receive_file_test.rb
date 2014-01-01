require 'unit/test_helper'

describe Pantry::Communication::FileService::ReceiveFile do

  class FakeReceiveService
    attr_accessor :sent
    def initialize
      @sent = []
    end
    def send_message(message)
      @sent << message
    end
  end

  let(:service)    { FakeReceiveService.new }
  let(:file_path)  { fixture_path("file_to_upload") }
  let(:receiver)   { Pantry::Communication::FileService::ReceiveFile.new(service) }

  def start_message(uuid)
    Pantry::Message.new.tap do |msg|
      msg.to = uuid
      msg << "START"
    end
  end

  def chunk(uuid, data = "binary data", offset: 0, size: 1_000)
    Pantry::Message.new.tap do |msg|
      msg.to = uuid
      msg[:chunk_offset] = offset
      msg[:chunk_size]   = size
      msg << "CHUNK"
      msg << data
    end
  end

  describe "#receive_file" do
    it "builds and returns file upload info when asked to receive a new file" do
      info = receiver.receive_file(12_000, "abc123")

      assert_not_nil info, "No info returned for the file info"
      assert_equal 36,       info.uuid.length
      assert_equal 12_000,   info.file_size
      assert_equal "abc123", info.checksum
    end

    it "creates and returns a tempfile path where the upload will go" do
      info = receiver.receive_file(12_000, "abc123")

      assert_not_nil info.uploaded_path, "Did not give a file path where upload will live"
      assert File.exists?(info.uploaded_path), "Did not create a tempfile for the upload"
    end
  end

  it "waits for a start message from the sender then sends initial chunk requests" do
    info = receiver.receive_file(5_000_000, "checksum")
    receiver.receive_message(start_message(info.uuid))

    pipeline_size = receiver.pipeline_size
    chunk_size    = receiver.chunk_size

    assert_equal pipeline_size, service.sent.length

    service.sent.each_with_index do |msg, i|
      assert_equal info.uuid, msg.to, "Message #{i} did not set the to field properly"
    end

    assert_equal ["FETCH", 0,              chunk_size], service.sent[0].body
    assert_equal ["FETCH", chunk_size,     chunk_size], service.sent[1].body
    assert_equal ["FETCH", chunk_size * 2, chunk_size], service.sent[2].body
  end

  it "writes out received chunks to the given save file path" do
    info = receiver.receive_file(
      File.size(file_path),
      "9cb63cb779e8c571db3199b783a36cc43cd9e7c076beeb496c39e9cc06196dc5"
    )
    receiver.receive_message(start_message(info.uuid))
    receiver.receive_message(chunk(info.uuid))

    assert_equal "binary data", File.read(info.uploaded_path)
  end

  it "keeps a certain number of chunk requests in the pipeline" do
    info = receiver.receive_file(5_000_000, "checksum")
    receiver.receive_message(start_message(info.uuid))
    service.sent = []

    receiver.receive_message(chunk(info.uuid))

    # We've already requested 10 chunks. Having received one chunk we request the 11th (0-based)
    assert_equal 1, service.sent.length
    assert_equal ["FETCH", receiver.chunk_size * 10, receiver.chunk_size], service.sent[0].body
  end

  it "doesn't add to the pipeline when the last chunk has been requested" do
    info = receiver.receive_file(500_000, "checksum")
    receiver.receive_message(start_message(info.uuid))
    service.sent = []

    receiver.receive_message(chunk(info.uuid))
    assert_equal 0, service.sent.length
  end

  it "sends the finished message to the client when the file upload is successful" do
    info = receiver.receive_file(
      File.size(file_path),
      "9cb63cb779e8c571db3199b783a36cc43cd9e7c076beeb496c39e9cc06196dc5"
    )
    receiver.receive_message(start_message(info.uuid))
    service.sent = []

    receiver.receive_message(chunk(info.uuid))

    assert_equal 1, service.sent.length
    assert_equal info.uuid, service.sent[0].to
    assert_equal ["FINISH"], service.sent[0].body

    assert info.finished?, "Did not mark info object as finished"
    assert_not_nil info.wait_for_finish(1)
  end

  it "fails and deletes the file if the checksum does not match after upload complete" do
    info = receiver.receive_file(File.size(file_path), "invalid")
    receiver.receive_message(start_message(info.uuid))
    service.sent = []

    receiver.receive_message(chunk(info.uuid))

    assert_false File.exists?(info.uploaded_path)

    error_message = service.sent[0]
    assert_not_nil error_message
    assert_equal info.uuid, error_message.to
    assert_equal "ERROR", error_message.body[0]
    assert_equal "Checksum did not match the uploaded file", error_message.body[1]
  end

  it "supports receiving file data chunks out-of-order" do
    receiver.chunk_size = 5
    info = receiver.receive_file(
      13, "c30facc0146cfaf7e64fea5399ccb2707a060c2d739218a1f3b20b15b8d6e89d"
    )
    receiver.receive_message(start_message(info.uuid))
    service.sent = []

    receiver.receive_message(chunk(info.uuid, "ry!",   offset: 10, size: 3))
    receiver.receive_message(chunk(info.uuid, "Hello", offset: 0,  size: 5))
    receiver.receive_message(chunk(info.uuid, " Pant", offset: 5,  size: 5))

    success_message = service.sent[0]
    assert_equal "FINISH", success_message.body[0]

    assert File.exists?(info.uploaded_path), "File was baleted?!"
    assert_equal "Hello Pantry!", File.read(info.uploaded_path)
  end

end
