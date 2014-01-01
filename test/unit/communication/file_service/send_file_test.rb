require 'unit/test_helper'

describe Pantry::Communication::FileService::SendFile do

  class FakeSendSocket
    attr_accessor :sent
    def initialize
      @sent = []
    end
    def send_message(message)
      @sent << message
    end
  end

  let(:socket)     { FakeSendSocket.new }
  let(:file_path)  { fixture_path("file_to_upload") }
  let(:sender)     { Pantry::Communication::FileService::SendFile.new(socket) }

  def fetch(uuid, seek, size)
    chunk = Pantry::Message.new
    chunk.from = uuid
    chunk << "FETCH"
    chunk << seek.to_s
    chunk << size.to_s
    chunk
  end

  describe "#send_file" do
    it "opens the file and sends the receiver the START command" do
      sender.send_file(file_path, "uuid")

      assert_equal 1, socket.sent.length

      start_message = socket.sent[0]
      assert_equal "uuid", start_message.to
      assert_equal "START", start_message.body[0]
    end
  end

  it "reads the requested chunk of file and sends it along to the receiver" do
    sender.send_file(file_path, "uuid")
    socket.sent = []

    sender.receive_message(fetch("uuid", 0, 5))

    assert_equal 1, socket.sent.length

    chunk_data = socket.sent[0]

    assert_equal "uuid", chunk_data.to
    assert_equal "CHUNK", chunk_data.body[0]
    assert_equal "Hello", chunk_data.body[1]
    assert_equal 0, chunk_data[:chunk_offset]
    assert_equal 5, chunk_data[:chunk_size]
  end

  it "supports sending multiple files at a time (keyed by UUID)" do
    sender.send_file(file_path, "uuid1")
    sender.send_file(file_path, "uuid2")
    sender.send_file(file_path, "uuid3")
    socket.sent = []

    sender.receive_message(fetch("uuid1", 0, 1))
    sender.receive_message(fetch("uuid2", 1, 1))
    sender.receive_message(fetch("uuid3", 2, 1))

    assert_equal "uuid1", socket.sent[0].to
    assert_equal "H",     socket.sent[0].body[1]

    assert_equal "uuid2", socket.sent[1].to
    assert_equal "e",     socket.sent[1].body[1]

    assert_equal "uuid3", socket.sent[2].to
    assert_equal "l",     socket.sent[2].body[1]
  end

  it "ignores FETCH requests of an unknown uuid" do
    sender.receive_message(fetch("uuid1", 0, 1))
    assert_equal 0, socket.sent.length
  end

  it "closes up the file associated with the UUID on FINISH" do
    sender.send_file(file_path, "uuid")

    finish = Pantry::Message.new
    finish.from = "uuid"
    finish << "FINISH"

    sender.receive_message(finish)

    # See that further requests to this UUID are dropped
    socket.sent = []
    sender.receive_message(fetch("uuid", 0, 1))
    assert_equal [], socket.sent
  end

end
