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

  it "exposes the given UUID for the wait list" do
    sender = Pantry::Communication::SendFile.new(networking, file_path, receiver_uuid: "receiver-uuid")

    assert_equal "receiver-uuid", sender.uuid
  end

  it "generates its own UUID if none given (server-side sending). Doesn't send start message" do
    sender = Pantry::Communication::SendFile.new(networking, file_path)

    assert_equal 0, networking.sent.length
    assert_not_nil sender.uuid
  end

  it "opens the file and sends the receiver the START command" do
    sender = Pantry::Communication::SendFile.new(networking, file_path, receiver_uuid: "receiver-uuid")

    assert_equal 1, networking.sent.length

    start_message = networking.sent[0]
    assert_equal "START", start_message.body[0]
    assert_equal "receiver-uuid", start_message.uuid
  end

  it "reads the requested chunk of file and sends it along to the receiver" do
    sender = Pantry::Communication::SendFile.new(networking, file_path, receiver_uuid: "receiver-uuid")
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
    sender = Pantry::Communication::SendFile.new(networking, file_path, receiver_uuid: "receiver-uuid")
    networking.sent = []

    assert_false sender.finished?

    finished = Pantry::Message.new
    finished << "FINISH"

    sender.receive_message(finished)
    assert sender.finished?
  end

  describe "progress listeners" do

    class TestSendFileListener
      attr_reader :progress_size, :steps, :error_message, :finished

      def start_progress(progress_size)
        @progress_size = progress_size
      end

      def step_progress(step_amount)
        @steps ||= []
        @steps << step_amount
      end

      def error(message)
        @error_message = message
      end

      def finished
        @finished = true
      end
    end

    let(:listener) { TestSendFileListener.new }
    let(:sender) {
      Pantry::Communication::SendFile.new(
        networking, file_path, receiver_uuid: "receiver-uuid", listener: listener
      )
    }

    it "triggers progress callbacks on file transfer" do
      chunk1 = Pantry::Message.new
      chunk1 << "FETCH"
      chunk1 << "0"
      chunk1 << "5"

      sender.receive_message(chunk1)

      assert_equal 15, listener.progress_size
      assert_equal [5], listener.steps
    end

    it "notifies on errors" do
      errored = Pantry::Message.new
      errored << "ERROR"
      errored << "This is an error message"

      sender.receive_message(errored)

      assert_equal "This is an error message", listener.error_message
    end

    it "notifies on completion" do
      finished = Pantry::Message.new
      finished << "FINISH"

      sender.receive_message(finished)

      assert listener.finished, "Listener was not told that we were done"
    end

  end

end
