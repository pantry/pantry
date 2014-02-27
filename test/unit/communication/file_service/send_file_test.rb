require 'unit/test_helper'

describe Pantry::Communication::FileService::SendFile do

  mock_ui!

  class FakeSendService
    attr_accessor :sent
    def initialize
      @sent = []
    end
    def send_message(identity, message)
      @sent << {identity: identity, message: message}
    end
  end

  let(:service)    { FakeSendService.new }
  let(:file_path)  { fixture_path("file_to_upload") }
  let(:sender)     { Pantry::Communication::FileService::SendFile.new(service) }

  def fetch(uuid, seek, size)
    chunk = Pantry::Message.new
    chunk.to = uuid
    chunk << "FETCH"
    chunk << seek.to_s
    chunk << size.to_s
    chunk
  end

  describe "#send_file" do
    it "opens the file and sends the receiver the START command" do
      sender.send_file(file_path, "receiver_ident", "file_uuid")

      assert_equal 1, service.sent.length

      start_message = service.sent[0]
      assert_equal "receiver_ident", start_message[:identity]
      assert_equal "file_uuid", start_message[:message].to
      assert_equal "START", start_message[:message].body[0]
    end

    it "returns a sending info object for callers to use" do
      info = sender.send_file(file_path, "receiver_ident", "file_uuid")

      assert_not_nil info
      assert_equal file_path, info.path
    end
  end

  it "reads the requested chunk of file and sends it along to the receiver" do
    sender.send_file(file_path, "receiver", "file_uuid")
    service.sent = []

    sender.receive_message("receiver", fetch("file_uuid", 0, 5))

    assert_equal 1, service.sent.length

    chunk_data = service.sent[0][:message]

    assert_equal "file_uuid", chunk_data.to
    assert_equal "CHUNK", chunk_data.body[0]
    assert_equal "Hello", chunk_data.body[1]
    assert_equal 0, chunk_data[:chunk_offset]
    assert_equal 5, chunk_data[:chunk_size]
  end

  it "supports sending multiple files at a time (keyed by UUID)" do
    sender.send_file(file_path, "receiver", "uuid1")
    sender.send_file(file_path, "receiver", "uuid2")
    sender.send_file(file_path, "receiver", "uuid3")
    service.sent = []

    sender.receive_message("receiver", fetch("uuid1", 0, 1))
    sender.receive_message("receiver", fetch("uuid2", 1, 1))
    sender.receive_message("receiver", fetch("uuid3", 2, 1))

    assert_equal "uuid1", service.sent[0][:message].to
    assert_equal "H",     service.sent[0][:message].body[1]

    assert_equal "uuid2", service.sent[1][:message].to
    assert_equal "e",     service.sent[1][:message].body[1]

    assert_equal "uuid3", service.sent[2][:message].to
    assert_equal "l",     service.sent[2][:message].body[1]
  end

  it "ignores FETCH requests of an unknown uuid" do
    sender.receive_message("receiver", fetch("uuid1", 0, 1))
    assert_equal 0, service.sent.length
  end

  it "closes up the file associated with the UUID on FINISH and notifies info" do
    info = sender.send_file(file_path, "receiver", "uuid")

    finish = Pantry::Message.new
    finish.to = "uuid"
    finish << "FINISH"

    sender.receive_message("receiver", finish)

    # See that further requests to this UUID are dropped
    service.sent = []
    sender.receive_message("receiver", fetch("uuid", 0, 1))
    assert_equal [], service.sent

    assert info.finished?, "Info object was not finished"
    assert_not_nil info.wait_for_finish(1)
  end

end
