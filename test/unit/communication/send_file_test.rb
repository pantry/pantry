require 'unit/test_helper'

describe Pantry::Communication::SendFile do

  class FakeSendNetwork
    attr_accessor :sent
    def initialize
      @sent = []
    end
    def send_message(message)
      @sent << message
    end
  end

  let(:networking) { FakeSendNetwork.new }
  let(:file_path)  { File.expand_path("../../../fixtures/file_to_upload", __FILE__) }

  it "opens the file and sends the receiver the START command" do
    sender = Pantry::Communication::SendFile.new(networking, file_path, "receiver-uuid")

    assert_equal 1, networking.sent.length

    start_message = networking.sent[0]
    assert_equal "START", start_message.body[0]
    assert_equal "receiver-uuid", start_message.uuid
  end

  it "reads the requested chunk of file and sends it along to the receiver" do
    sender = Pantry::Communication::SendFile.new(networking, file_path, "receiver-uuid")
    networking.sent = []

    chunk1 = Pantry::Message.new
    chunk1 << "FETCH"
    chunk1 << "0"
    chunk1 << "5"

    sender.receive_message(chunk1)

    assert_equal 1, networking.sent.length

    chunk_data = networking.sent[0]

    assert_equal "CHUNK", chunk_data.body[0]
    assert_equal "Hello", chunk_data.body[1]
    assert_equal 0, chunk_data[:chunk_offset]
    assert_equal 5, chunk_data[:chunk_size]
  end

  it "closes down on the FINISH command" do
    sender = Pantry::Communication::SendFile.new(networking, file_path, "receiver-uuid")
    networking.sent = []

    finished = Pantry::Message.new
    finished << "FINISH"

    sender.receive_message(finished)
  end

  it "does something on ERROR" do
    sender = Pantry::Communication::SendFile.new(networking, file_path, "receiver-uuid")
    networking.sent = []

    errored = Pantry::Message.new
    errored << "ERROR"
    errored << "This is an error message"

    sender.receive_message(errored)
  end

end
